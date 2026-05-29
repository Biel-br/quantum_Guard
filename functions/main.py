import os
import io
import json
import base64
import hashlib
from datetime import datetime, timezone

from bs4 import BeautifulSoup
from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn
from firebase_functions.core import init
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
import requests
import json as _json
try:
    from google.cloud import secretmanager
except Exception:
    secretmanager = None

initialize_app()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ─────────────────────────────────────────────
# Domínios confiáveis — nunca alertados
# ─────────────────────────────────────────────
ALLOWLIST_DOMINIOS = {
    "duolingo.com", "twitch.tv", "github.com", "linkedin.com",
    "google.com", "microsoft.com", "apple.com",
}

EXTENSOES_PERIGOSAS = {
    ".exe": "Executável Windows",        ".bat": "Script de lote Windows",
    ".cmd": "Script de comando Windows", ".vbs": "Script Visual Basic",
    ".ps1": "Script PowerShell",         ".msi": "Instalador Windows",
    ".dll": "Biblioteca de sistema",     ".scr": "Protetor de tela / Malware",
    ".jar": "Executável Java",           ".sh":  "Script Shell Linux",
    ".py":  "Script Python",             ".js":  "Script JavaScript",
    ".hta": "Aplicação HTML executável", ".com": "Executável DOS",
    ".pif": "Arquivo de informação de programa",
}

EXTENSOES_IMAGEM = {".png", ".jpg", ".jpeg", ".bmp", ".webp", ".gif"}

# Palavras que disparam alerta de engenharia social via OCR
GATILHOS_OCR = [
    "atualização cadastral", "dados bancários", "evite bloqueios",
    "sua conta", "senha", "clique aqui", "acesso bloqueado",
    "confirme seus dados", "cartão de crédito", "pix",
]


# ══════════════════════════════════════════════
# 1. GLOBAIS — inicializadas no @init
# ══════════════════════════════════════════════
_db = None
_regras_yara = None

@init
def inicializar():
    global _db, _regras_yara
    _db = firestore.client()
    try:
        import yara
        caminho_yar = os.path.join(BASE_DIR, "malware.yar")
        if os.path.exists(caminho_yar):
            _regras_yara = yara.compile(filepath=caminho_yar)
    except Exception as e:
        print(f"Erro ao carregar YARA: {e}")


# ══════════════════════════════════════════════
# 2. HELPERS GERAIS
# ══════════════════════════════════════════════
def carregar_json(caminho, chave):
    try:
        with open(os.path.join(BASE_DIR, "assets", caminho)) as f:
            return json.load(f).get(chave, [])
    except Exception:
        return []

def uid_do_request(req: https_fn.CallableRequest):
    return req.auth.uid if req.auth else None

def salvar_deteccao(uid, hash_str, nome_arquivo, ameaca, status):
    try:
        _db.collection("hashes_verificados").add({
            "uid": uid, "nomeArquivo": nome_arquivo, "hash": hash_str,
            "ameaca": ameaca, "status": status,
            "data": datetime.now(timezone.utc).isoformat(), "revisado": False,
        })
    except Exception as e:
        print(f"Erro ao salvar no Firestore: {e}")


# ══════════════════════════════════════════════
# 3. HELPERS DE ANÁLISE DE EMAIL
# ══════════════════════════════════════════════
def extrair_corpo_email(payload):
    """
    Percorre o payload recursivamente e retorna (texto_puro, html).
    Equivalente ao extrair_partes_email() do arquivo 2, adaptado para
    trabalhar em memória sem salvar nada em disco.
    """
    texto_puro = ""
    html = ""
    mime = payload.get("mimeType", "")

    if mime.startswith("multipart/"):
        for sub in payload.get("parts", []):
            t, h = extrair_corpo_email(sub)
            texto_puro += t
            html += h
    else:
        dados_b64 = payload.get("body", {}).get("data")
        if dados_b64:
            conteudo = base64.urlsafe_b64decode(dados_b64 + "==").decode("utf-8", errors="ignore")
            if mime == "text/plain":
                texto_puro = conteudo
            elif mime == "text/html":
                html = conteudo

    return texto_puro, html


def extrair_links_html(html):
    """Extrai todos os hrefs únicos do corpo HTML do email."""
    if not html:
        return []
    soup = BeautifulSoup(html, "lxml")
    return list({tag["href"] for tag in soup.find_all("a", href=True)})


def extrair_partes_anexo(payload):
    """Retorna apenas as partes que possuem arquivo anexado (com filename)."""
    partes = []
    mime = payload.get("mimeType", "")
    if mime.startswith("multipart/"):
        for sub in payload.get("parts", []):
            partes.extend(extrair_partes_anexo(sub))
    else:
        filename = payload.get("filename", "")
        body = payload.get("body", {})
        if filename and (body.get("attachmentId") or body.get("data")):
            partes.append(payload)
    return partes


def analisar_autenticacao(headers):
    """Verifica SPF, DKIM e DMARC nos cabeçalhos do email."""
    auth_results = ""
    for h in headers:
        if h["name"].lower() == "authentication-results":
            auth_results = h["value"].lower()
            break
    return {
        "spf":   "spf=pass"   in auth_results,
        "dkim":  "dkim=pass"  in auth_results,
        "dmarc": "dmarc=pass" in auth_results,
        "raw":   auth_results or "Não disponível",
    }


def extrair_dominio_remetente(remetente):
    """Extrai o domínio puro do campo From: ex. 'Nome <user@banco.com>' → 'banco.com'"""
    if "@" in remetente:
        return remetente.split("@")[-1].replace(">", "").strip().lower()
    return ""


def verificar_links_email(links):
    """
    Verifica cada link extraído do corpo do email contra a lista de URLs
    maliciosas, ignorando domínios da allowlist.
    """
    lista_urls = carregar_json("urls_maliciosas.json", "urls")
    resultados = []
    for url in links:
        dominio = (
            url.lower()
            .replace("https://", "").replace("http://", "").replace("www.", "")
            .split("/")[0].strip()
        )
        if dominio in ALLOWLIST_DOMINIOS:
            continue
        exata   = dominio in lista_urls
        parcial = any(mal in dominio for mal in lista_urls)
        ameaca  = exata or parcial
        if ameaca:
            resultados.append({
                "url": url, "dominio": dominio,
                "tipo": "Domínio malicioso conhecido" if exata else "Domínio suspeito",
            })
    return resultados


def analisar_imagem_ocr(bytes_imagem, nome_arquivo):
    """
    Roda OCR (Tesseract) nos bytes da imagem em memória — sem salvar em disco.
    Procura por gatilhos de engenharia social no texto extraído.
    """
    _, ext = os.path.splitext(nome_arquivo)
    if ext.lower() not in EXTENSOES_IMAGEM:
        return False, ""
    try:
        import pytesseract
        from PIL import Image
        imagem = Image.open(io.BytesIO(bytes_imagem))
        texto  = pytesseract.image_to_string(imagem, lang="por")
        ameaca = any(g in texto.lower() for g in GATILHOS_OCR)
        return ameaca, texto
    except Exception as e:
        print(f"Erro OCR em {nome_arquivo}: {e}")
        return False, ""


def analisar_anexo(bytes_arquivo, nome_arquivo):
    """
    Pipeline completo de análise de um anexo:
      hash → extensão → YARA → OCR (se imagem)
    """
    # — Hash —
    hash_calculado   = hashlib.sha256(bytes_arquivo).hexdigest()
    lista_maliciosos = carregar_json("hashes_maliciosos.json", "hashes")
    hash_ameaca      = hash_calculado in lista_maliciosos

    # — Extensão —
    _, ext   = os.path.splitext(nome_arquivo)
    ext      = ext.lower()
    ext_perigosa = ext in EXTENSOES_PERIGOSAS

    # — YARA —
    yara_matches = []
    yara_ameaca  = False
    if _regras_yara:
        try:
            matches     = _regras_yara.match(data=bytes_arquivo)
            yara_matches = [{
                "regra":      m.rule,
                "descricao":  m.meta.get("description", "Sem descrição"),
                "severidade": m.meta.get("severidade", "desconhecida"),
            } for m in matches]
            yara_ameaca = bool(yara_matches)
        except Exception as e:
            print(f"Erro YARA em {nome_arquivo}: {e}")

    # — OCR (só para imagens) —
    ocr_ameaca = False
    ocr_texto  = ""
    if ext in EXTENSOES_IMAGEM:
        ocr_ameaca, ocr_texto = analisar_imagem_ocr(bytes_arquivo, nome_arquivo)

    ameaca_geral = hash_ameaca or ext_perigosa or yara_ameaca or ocr_ameaca

    return {
        "nome":               nome_arquivo,
        "hash":               hash_calculado,
        "hash_ameaca":        hash_ameaca,
        "extensao":           ext,
        "extensao_perigosa":  ext_perigosa,
        "descricao_extensao": EXTENSOES_PERIGOSAS.get(ext, "Extensão segura"),
        "yara_matches":       yara_matches,
        "yara_ameaca":        yara_ameaca,
        "ocr_ameaca":         ocr_ameaca,
        "ocr_texto":          ocr_texto[:500] if ocr_texto else "",  # evita payload gigante
        "ameaca":             ameaca_geral,
        "status":             "⚠️ Ameaça detectada!" if ameaca_geral else "✅ Anexo limpo",
    }


# ══════════════════════════════════════════════
# 4. ROTA: HASH SCANNER
# ══════════════════════════════════════════════
@https_fn.on_call()
def hash_scan(req: https_fn.CallableRequest):
    bytes_arquivo = req.data.get("bytes")
    hash_enviado  = req.data.get("hash")
    nome_arquivo  = req.data.get("nome", "arquivo_desconhecido")

    hash_calculado = (
        hashlib.sha256(bytes(bytes_arquivo)).hexdigest()
        if bytes_arquivo else hash_enviado
    )
    if not hash_calculado:
        return {"erro": "Nenhum dado ou hash fornecido"}

    lista_maliciosos = carregar_json("hashes_maliciosos.json", "hashes")
    ameaca = hash_calculado in lista_maliciosos
    status = "⚠️ Ameaça detectada!" if ameaca else "✅ Arquivo limpo"

    uid = uid_do_request(req)
    if uid:
        salvar_deteccao(uid, hash_calculado, nome_arquivo, ameaca, status)

    return {"hash": hash_calculado, "ameaca": ameaca, "status": status}


# ══════════════════════════════════════════════
# 5. ROTA: VERIFICADOR DE URL
# ══════════════════════════════════════════════
@https_fn.on_call()
def url_verificar(req: https_fn.CallableRequest):
    url_raw  = req.data.get("url", "")
    dominio  = (
        url_raw.lower()
        .replace("https://", "").replace("http://", "").replace("www.", "")
        .split("/")[0].strip()
    )
    lista_urls  = carregar_json("urls_maliciosas.json", "urls")
    exata       = dominio in lista_urls
    parcial     = any(mal in dominio for mal in lista_urls)
    ameaca      = exata or parcial
    tipo_ameaca = (
        "Domínio malicioso conhecido" if exata
        else "Domínio suspeito detectado" if parcial
        else None
    )
    return {
        "url": url_raw, "dominio": dominio, "ameaca": ameaca,
        "tipo_ameaca": tipo_ameaca,
        "status": "⚠️ URL Perigosa!" if ameaca else "✅ URL Segura",
    }


# ══════════════════════════════════════════════
# 6. ROTA: VERIFICADOR DE EXTENSÃO
# ══════════════════════════════════════════════
@https_fn.on_call()
def extensao_verificar(req: https_fn.CallableRequest):
    arquivos  = req.data.get("arquivos", [])
    resultados = []
    perigosos  = 0
    for nome in arquivos:
        _, ext = os.path.splitext(nome)
        ext    = ext.lower()
        perigosa = ext in EXTENSOES_PERIGOSAS
        if perigosa:
            perigosos += 1
        resultados.append({
            "nome": nome, "extensao": ext, "perigosa": perigosa,
            "descricao": EXTENSOES_PERIGOSAS.get(ext, "Extensão segura"),
        })
    return {
        "resultados": resultados, "total": len(arquivos),
        "perigosos": perigosos, "seguros": len(arquivos) - perigosos,
    }


# ══════════════════════════════════════════════
# 7. ROTA: YARA SCANNER
# ══════════════════════════════════════════════
@https_fn.on_call()
def yara_scan(req: https_fn.CallableRequest):
    bytes_arquivo = req.data.get("bytes")
    if not bytes_arquivo:
        return {"erro": "Bytes não fornecidos"}
    if _regras_yara is None:
        return {"erro": "Regras YARA não carregadas. Verifique se malware.yar existe em functions/."}
    try:
        matches = _regras_yara.match(data=bytes(bytes_arquivo))
        resultado_matches = [{
            "regra":      m.rule,
            "descricao":  m.meta.get("description", "Sem descrição"),
            "severidade": m.meta.get("severidade", "desconhecida"),
        } for m in matches]
        ameaca = bool(resultado_matches)
        return {
            "ameaca": ameaca, "matches": resultado_matches,
            "total_matches": len(resultado_matches),
            "status": "⚠️ Ameaças detectadas!" if ameaca else "✅ Nenhuma ameaça detectada",
        }
    except Exception as e:
        return {"erro": f"Erro no YARA: {str(e)}"}


# ══════════════════════════════════════════════
# 8. ROTA: GMAIL SCANNER
# ══════════════════════════════════════════════
@https_fn.on_call()
def gmail_escanear_emails(req: https_fn.CallableRequest):
    """
    Busca os últimos N emails do Gmail, analisa corpo + links + anexos,
    salva no Firestore com visualizado=False e devolve os resultados.
    A exclusão do Firestore só acontece quando o app chamar
    gmail_confirmar_leitura() com os doc_ids retornados.

    Payload:
        access_token  str   — OAuth2 token do Gmail
        max_emails    int   — Quantos emails buscar (padrão: 5)
    """
    access_token = req.data.get("access_token")
    max_emails   = int(req.data.get("max_emails", 5))
    uid          = uid_do_request(req)

    if not access_token:
        return {"erro": "Token de acesso Gmail não fornecido"}

    # — Conecta à Gmail API —
    try:
        creds   = Credentials(token=access_token)
        servico = build("gmail", "v1", credentials=creds, cache_discovery=False)
    except Exception as e:
        return {"erro": f"Falha ao conectar ao Gmail: {str(e)}"}

    # — Lista as mensagens mais recentes (paginação para atingir max_emails) —
    try:
        mensagens = []
        page_token = None
        remaining = max_emails
        # Gmail API permite no máximo 500 por página; fazemos múltiplas chamadas
        while remaining > 0:
            page_max = min(500, remaining)
            if page_token:
                resposta = servico.users().messages().list(
                    userId="me", maxResults=page_max, pageToken=page_token
                ).execute()
            else:
                resposta = servico.users().messages().list(
                    userId="me", maxResults=page_max
                ).execute()

            msgs = resposta.get("messages", [])
            if not msgs:
                break
            mensagens.extend(msgs)
            page_token = resposta.get("nextPageToken")
            # Se não houver mais páginas, encerra
            if not page_token:
                break
            remaining -= len(msgs)
    except Exception as e:
        return {"erro": f"Falha ao listar emails: {str(e)}"}

    resultados_emails = []

    for msg_info in mensagens:
        msg_id = msg_info["id"]

        try:
            msg = servico.users().messages().get(
                userId="me", id=msg_id, format="full"
            ).execute()
        except Exception as e:
            print(f"Erro ao buscar msg {msg_id}: {e}")
            continue

        headers    = msg.get("payload", {}).get("headers", [])
        payload    = msg.get("payload", {})

        # ── Cabeçalhos ──────────────────────────────
        assunto    = next((h["value"] for h in headers if h["name"] == "Subject"), "")
        remetente  = next((h["value"] for h in headers if h["name"] == "From"), "")
        data_email = next((h["value"] for h in headers if h["name"] == "Date"), "")
        dominio_remetente = extrair_dominio_remetente(remetente)

        # ── Autenticação SPF / DKIM / DMARC ─────────
        auth = analisar_autenticacao(headers)
        remetente_suspeito = (
            not (auth["spf"] or auth["dkim"] or auth["dmarc"])
            and dominio_remetente not in ALLOWLIST_DOMINIOS
        )

        # ── Corpo do email → links ───────────────────
        _, html        = extrair_corpo_email(payload)
        links          = extrair_links_html(html)
        links_perigosos = verificar_links_email(links)

        # ── Anexos ──────────────────────────────────
        partes_anexo    = extrair_partes_anexo(payload)
        anexos_analisados = []

        for parte in partes_anexo:
            nome_arquivo  = parte.get("filename", "sem_nome")
            body          = parte.get("body", {})
            attachment_id = body.get("attachmentId")
            dados_b64     = body.get("data")

            if attachment_id:
                try:
                    resp      = servico.users().messages().attachments().get(
                        userId="me", messageId=msg_id, id=attachment_id
                    ).execute()
                    dados_b64 = resp.get("data", "")
                except Exception as e:
                    print(f"Erro ao baixar {nome_arquivo}: {e}")
                    continue

            if not dados_b64:
                continue

            try:
                bytes_arquivo = base64.urlsafe_b64decode(dados_b64 + "==")
            except Exception as e:
                print(f"Erro ao decodificar {nome_arquivo}: {e}")
                continue

            analise = analisar_anexo(bytes_arquivo, nome_arquivo)
            anexos_analisados.append(analise)

        # ── Veredicto geral do email ─────────────────
        ameaca_anexos = any(a["ameaca"] for a in anexos_analisados)
        ameaca_links  = bool(links_perigosos)
        email_ameaca  = ameaca_anexos or ameaca_links or remetente_suspeito

        resultado_email = {
            "msg_id":              msg_id,
            "assunto":             assunto,
            "remetente":           remetente,
            "dominio_remetente":   dominio_remetente,
            "data_email":          data_email,
            # Autenticação
            "auth_spf":            auth["spf"],
            "auth_dkim":           auth["dkim"],
            "auth_dmarc":          auth["dmarc"],
            "remetente_suspeito":  remetente_suspeito,
            # Links
            "total_links":         len(links),
            "links_perigosos":     links_perigosos,
            # Anexos
            "total_anexos":        len(anexos_analisados),
            "anexos":              anexos_analisados,
            # Veredicto
            "ameaca":              email_ameaca,
            "status":              "⚠️ Email perigoso!" if email_ameaca else "✅ Email seguro",
        }

        # ── Salva no Firestore com visualizado=False ─
        # (a exclusão só ocorre quando o app chamar gmail_confirmar_leitura)
        doc_id = None
        if uid:
            try:
                _, doc_ref = _db.collection("emails_analisados_temp").add({
                    **resultado_email,
                    "uid":         uid,
                    "analisado_em": datetime.now(timezone.utc).isoformat(),
                    "visualizado": False,
                })
                doc_id = doc_ref.id
            except Exception as e:
                print(f"Erro ao salvar doc: {e}")

        resultado_email["doc_id"] = doc_id
        resultados_emails.append(resultado_email)

    # ── Resumo ───────────────────────────────────────
    total_ameacas = sum(1 for e in resultados_emails if e["ameaca"])
    total_anexos  = sum(e["total_anexos"] for e in resultados_emails)

    return {
        "total_emails":     len(resultados_emails),
        "total_com_anexos": sum(1 for e in resultados_emails if e["total_anexos"] > 0),
        "total_anexos":     total_anexos,
        "total_ameacas":    total_ameacas,
        "emails":           resultados_emails,
        "resumo": (
            f"⚠️ {total_ameacas} email(s) com ameaças detectadas em {total_anexos} anexo(s) analisados!"
            if total_ameacas
            else f"✅ Todos os {len(resultados_emails)} emails estão seguros ({total_anexos} anexo(s) analisados)"
        ),
    }


# ══════════════════════════════════════════════
# 9. ROTA: CONFIRMAR LEITURA E EXCLUIR
# ══════════════════════════════════════════════
@https_fn.on_call()
def gmail_confirmar_leitura(req: https_fn.CallableRequest):
    """
    Chamada pelo app depois que o usuário visualizou os resultados.
    Apaga os docs temporários do Firestore para o uid autenticado.

    Payload:
        doc_ids  list[str]  — doc_ids retornados por gmail_escanear_emails
    """
    doc_ids = req.data.get("doc_ids", [])
    uid     = uid_do_request(req)

    if not doc_ids:
        return {"erro": "Nenhum doc_id fornecido"}

    apagados = 0
    com_erro = 0

    for doc_id in doc_ids:
        try:
            ref = _db.collection("emails_analisados_temp").document(doc_id)
            doc = ref.get()

            if not doc.exists:
                continue
            # Segurança: só apaga doc do próprio usuário
            if uid and doc.to_dict().get("uid") != uid:
                com_erro += 1
                continue

            ref.delete()
            apagados += 1
        except Exception as e:
            print(f"Erro ao apagar doc {doc_id}: {e}")
            com_erro += 1

    return {
        "apagados": apagados,
        "com_erro": com_erro,
        "status": (
            f"✅ {apagados} registro(s) removidos do banco."
            if not com_erro
            else f"⚠️ {apagados} removidos, {com_erro} com erro."
        ),
    }


# ══════════════════════════════════════════════
# 10. FUNÇÃO AGENDADA: VARREDURA AUTOMÁTICA POR USUÁRIO
# ══════════════════════════════════════════════
from firebase_functions import scheduler_fn
from firebase_functions.scheduler_fn import Timezone


@scheduler_fn.on_schedule(schedule="*/15 * * * *", timezone=Timezone("UTC"))
def gmail_agendada(event: scheduler_fn.ScheduledEvent):
    """
    Executa periodicamente a varredura para todos os usuários que tenham
    um `refresh_token` salvo em `usuarios_tokens`.

    - Lê `functions/credentials.json` para obter client_id e client_secret
    - Troca `refresh_token` por `access_token` via endpoint OAuth2
    - Executa a lógica de escaneamento (mesma de `gmail_escanear_emails`)
    - Atualiza `usuarios_tokens` com `access_token` e salva os resultados em
      `emails_analisados_temp` com `uid` correspondente
    """
    # Carrega credenciais do cliente OAuth — preferir Secret Manager
    client_id = None
    client_secret = None
    secret_name = os.environ.get("OAUTH_CREDENTIALS_SECRET")
    if secret_name and secretmanager:
        try:
            client = secretmanager.SecretManagerServiceClient()
            # secret_name deve ser do formato 'projects/PROJECT_ID/secrets/NAME/versions/VERSION'
            resp = client.access_secret_version(name=secret_name)
            payload = resp.payload.data.decode("utf-8")
            creds_file = _json.loads(payload)
            client_cfg = creds_file.get("installed") or creds_file.get("web") or {}
            client_id = client_cfg.get("client_id")
            client_secret = client_cfg.get("client_secret")
        except Exception as e:
            print(f"gmail_agendada: falha ao ler segredo {secret_name}: {e}")

    if not client_id or not client_secret:
        # Fallback local file (apenas para desenvolvimento)
        try:
            with open(os.path.join(BASE_DIR, "credentials.json"), "r") as f:
                creds_file = _json.load(f)
            client_cfg = creds_file.get("installed") or creds_file.get("web") or {}
            client_id = client_cfg.get("client_id")
            client_secret = client_cfg.get("client_secret")
        except Exception as e:
            print(f"gmail_agendada: não foi possível ler credentials.json: {e}")
            return

    if not client_id or not client_secret:
        print("gmail_agendada: client_id ou client_secret ausente nas credenciais")
        return

    # Busca todos os users com refresh_token salvo
    try:
        docs = list(_db.collection("usuarios_tokens").stream())
    except Exception as e:
        print(f"gmail_agendada: erro ao listar usuarios_tokens: {e}")
        return

    for doc in docs:
        uid = doc.id
        data = doc.to_dict() or {}
        refresh_token = data.get("refresh_token")
        if not refresh_token:
            continue

        # Tenta trocar refresh_token por access_token
        try:
            token_resp = requests.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "client_id": client_id,
                    "client_secret": client_secret,
                    "refresh_token": refresh_token,
                    "grant_type": "refresh_token",
                },
                timeout=15,
            )
            token_resp.raise_for_status()
            token_json = token_resp.json()
            access_token = token_json.get("access_token")
            if not access_token:
                print(f"gmail_agendada: sem access_token para uid={uid}")
                continue

            # Atualiza access_token no Firestore (preserva refresh_token)
            try:
                _db.collection("usuarios_tokens").document(uid).set({
                    "access_token": access_token,
                    "atualizado_em": datetime.now(timezone.utc),
                }, merge=True)
            except Exception as e:
                print(f"gmail_agendada: falha ao atualizar access_token para {uid}: {e}")

            # Constrói serviço Gmail e executa varredura (max 100 emails por execução)
            try:
                creds = Credentials(token=access_token)
                servico = build("gmail", "v1", credentials=creds, cache_discovery=False)
            except Exception as e:
                print(f"gmail_agendada: falha ao criar serviço Gmail para {uid}: {e}")
                continue

            # Reutiliza a lógica de paginação usada em gmail_escanear_emails
            max_emails = 100
            try:
                mensagens = []
                page_token = None
                remaining = max_emails
                while remaining > 0:
                    page_max = min(500, remaining)
                    if page_token:
                        resposta = servico.users().messages().list(
                            userId="me", maxResults=page_max, pageToken=page_token
                        ).execute()
                    else:
                        resposta = servico.users().messages().list(
                            userId="me", maxResults=page_max
                        ).execute()

                    msgs = resposta.get("messages", [])
                    if not msgs:
                        break
                    mensagens.extend(msgs)
                    page_token = resposta.get("nextPageToken")
                    if not page_token:
                        break
                    remaining -= len(msgs)
            except Exception as e:
                print(f"gmail_agendada: falha ao listar mensagens para {uid}: {e}")
                continue

            # Executa análise por mensagem (trecho adaptado)
            resultados_emails = []
            for msg_info in mensagens:
                msg_id = msg_info.get("id")
                try:
                    msg = servico.users().messages().get(userId="me", id=msg_id, format="full").execute()
                except Exception as e:
                    print(f"gmail_agendada: erro ao buscar msg {msg_id} para {uid}: {e}")
                    continue

                headers = msg.get("payload", {}).get("headers", [])
                payload = msg.get("payload", {})

                assunto = next((h["value"] for h in headers if h["name"] == "Subject"), "")
                remetente = next((h["value"] for h in headers if h["name"] == "From"), "")
                data_email = next((h["value"] for h in headers if h["name"] == "Date"), "")
                dominio_remetente = extrair_dominio_remetente(remetente)

                auth = analisar_autenticacao(headers)
                remetente_suspeito = (
                    not (auth["spf"] or auth["dkim"] or auth["dmarc"]) and dominio_remetente not in ALLOWLIST_DOMINIOS
                )

                _, html = extrair_corpo_email(payload)
                links = extrair_links_html(html)
                links_perigosos = verificar_links_email(links)

                partes_anexo = extrair_partes_anexo(payload)
                anexos_analisados = []
                for parte in partes_anexo:
                    nome_arquivo = parte.get("filename", "sem_nome")
                    body = parte.get("body", {})
                    attachment_id = body.get("attachmentId")
                    dados_b64 = body.get("data")

                    if attachment_id:
                        try:
                            resp = servico.users().messages().attachments().get(
                                userId="me", messageId=msg_id, id=attachment_id
                            ).execute()
                            dados_b64 = resp.get("data", "")
                        except Exception as e:
                            print(f"gmail_agendada: erro ao baixar {nome_arquivo} para {uid}: {e}")
                            continue

                    if not dados_b64:
                        continue

                    try:
                        bytes_arquivo = base64.urlsafe_b64decode(dados_b64 + "==")
                    except Exception as e:
                        print(f"gmail_agendada: erro ao decodificar {nome_arquivo} para {uid}: {e}")
                        continue

                    analise = analisar_anexo(bytes_arquivo, nome_arquivo)
                    anexos_analisados.append(analise)

                ameaca_anexos = any(a["ameaca"] for a in anexos_analisados)
                ameaca_links = bool(links_perigosos)
                email_ameaca = ameaca_anexos or ameaca_links or remetente_suspeito

                resultado_email = {
                    "msg_id": msg_id,
                    "assunto": assunto,
                    "remetente": remetente,
                    "dominio_remetente": dominio_remetente,
                    "data_email": data_email,
                    "auth_spf": auth["spf"],
                    "auth_dkim": auth["dkim"],
                    "auth_dmarc": auth["dmarc"],
                    "remetente_suspeito": remetente_suspeito,
                    "total_links": len(links),
                    "links_perigosos": links_perigosos,
                    "total_anexos": len(anexos_analisados),
                    "anexos": anexos_analisados,
                    "ameaca": email_ameaca,
                    "status": "⚠️ Email perigoso!" if email_ameaca else "✅ Email seguro",
                }

                # Salva no Firestore com visualizado=False
                doc_id = None
                try:
                    _, doc_ref = _db.collection("emails_analisados_temp").add({
                        **resultado_email,
                        "uid": uid,
                        "analisado_em": datetime.now(timezone.utc).isoformat(),
                        "visualizado": False,
                    })
                    doc_id = doc_ref.id
                except Exception as e:
                    print(f"gmail_agendada: erro ao salvar doc para {uid}: {e}")

                resultado_email["doc_id"] = doc_id
                resultados_emails.append(resultado_email)

            print(f"gmail_agendada: finalizada varredura para uid={uid}, total_emails={len(resultados_emails)}")
        except Exception as e:
            print(f"gmail_agendada: erro geral para uid={uid}: {e}")