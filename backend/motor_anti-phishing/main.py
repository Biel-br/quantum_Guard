import os
import json
import yara
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pypdf import PdfReader
import pytesseract
from PIL import Image
import leitor_gmail
import firebase_admin
from firebase_admin import credentials, firestore

# Use o arquivo JSON que você baixou do console do Firebase (Chaves de serviço)
cred = credentials.Certificate("quantum-guard-8bddf-firebase-adminsdk-fbsvc-f752e80f9f.json")
firebase_admin.initialize_app(cred)
db_firestore = firestore.client()

app = FastAPI(
    title="Quantum Guard - Patrulha em Segundo Plano",
    description="Motor autônomo que protege o Gmail e gera relatórios.",
    version="2.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

servico_gmail = leitor_gmail.autenticar_gmail()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PASTA_BACKEND = os.path.dirname(BASE_DIR)
CAMINHO_REGRAS = os.path.join(PASTA_BACKEND, "regras", "malware.yar")
ARQUIVO_DB = os.path.join(BASE_DIR, "historico_ameacas.json") # Nosso Banco de Dados

regras_yara = None
status_yara = "Carregado com sucesso"
try:
    if os.path.exists(CAMINHO_REGRAS): regras_yara = yara.compile(filepath=CAMINHO_REGRAS)
    else: status_yara = "ERRO: Regras não encontradas"
except Exception as e: status_yara = f"ERRO YARA: {e}"

# ==========================================
# FUNÇÕES DE APOIO (TRADUTOR E BANCO DE DADOS)
# ==========================================

def gerar_relatorio_humano(ameacas):
    texto = "Nós removemos este e-mail da sua caixa de entrada porque ele contém armadilhas disfarçadas.\n\n"
    regras_acionadas = [a["regra_acionada"] for a in ameacas]
    
    if "DetectarRansomware" in regras_acionadas:
        texto += "• Ameaça de Extorsão: Existe um arquivo aqui que tenta bloquear seu celular ou computador para cobrar um 'resgate' em dinheiro (geralmente em criptomoedas).\n"
    if "DetectarKeylogger" in regras_acionadas:
        texto += "• Espião de Teclado: Encontramos um vírus oculto que tenta copiar tudo o que você digita, como suas senhas do banco, mensagens e dados de cartão.\n"
    if "DetectarShellcode" in regras_acionadas or "DetectarBackdoor" in regras_acionadas:
        texto += "• Invasão de Privacidade: Há um programa perigoso tentando abrir uma 'porta oculta' para alguém controlar seu aparelho à distância.\n"
    if "DetectarPhishingPorImagem" in regras_acionadas:
        texto += "• Engenharia Social: Identificamos uma imagem tentando se passar por um aviso urgente do banco para roubar seus dados (Atualização Cadastral falsa).\n"

    texto += "\nVocê não precisa se preocupar ou fazer nada. O Quantum Guard já isolou o perigo para você!"
    return texto

def salvar_ameaca_no_db(dados_ameaca):
    """Envia a ameaça direto para a nuvem para o Flutter apitar na hora."""
    try:
        dados_ameaca["data_bloqueio"] = datetime.now().strftime("%d/%m/%Y %H:%M")
        # Isso aqui é o que dispara o 'listen' no seu app Flutter
        db_firestore.collection('logs_seguranca').add(dados_ameaca)
        print("✅ Alerta enviado para o Firebase!")
    except Exception as e:
        print(f"❌ Erro ao enviar para o Firebase: {e}")

def neutralizar_email(msg_id):
    """Remove a etiqueta INBOX e adiciona SPAM usando a API do Gmail."""
    try:
        servico_gmail.users().messages().modify(
            userId='me', id=msg_id, 
            body={'addLabelIds': ['SPAM'], 'removeLabelIds': ['INBOX']}
        ).execute()
        return True
    except Exception as e:
        print(f"Erro ao neutralizar: {e}")
        return False

# ==========================================
# ROTAS DA API
# ==========================================

@app.get("/api/v1/dashboard/historico")
def obter_historico_dashboard():
    """Rota leve que o app Flutter vai chamar para montar os gráficos e listas."""
    if not os.path.exists(ARQUIVO_DB):
        return {"ameacas_bloqueadas": [], "total": 0}
    
    with open(ARQUIVO_DB, "r", encoding="utf-8") as f:
        historico = json.load(f)
        
    return {"ameacas_bloqueadas": historico, "total": len(historico)}

@app.get("/api/v1/patrulha/executar")
def executar_patrulha_invisivel(quantidade: int = 50):
    """Rota que varre os últimos e-mails, neutraliza os ruins e salva no DB."""
    resultados = servico_gmail.users().messages().list(userId='me', q='is:unread in:inbox -category:promotions', maxResults=quantidade).execute()
    mensagens = resultados.get('messages', [])
    
    ameacas_neutralizadas_agora = 0

    for msg in mensagens:
        msg_id = msg['id']
        email_completo = servico_gmail.users().messages().get(userId='me', id=msg_id, format='full').execute()
        payload = email_completo['payload']
        headers = payload.get('headers', [])
        
        assunto = "Sem Assunto"
        remetente = "Desconhecido"
        for header in headers:
            if header['name'] == 'Subject': assunto = header['value']
            if header['name'] == 'From': remetente = header['value']

        dominio = leitor_gmail.extrair_dominio(remetente)
        spf, dkim, dmarc = leitor_gmail.analisar_autenticacao(headers)

        # Se não passou na AllowList, faz o Deep Scan
        if not (dominio in leitor_gmail.ALLOWLIST_DOMINIOS and spf and dkim and dmarc):
            if 'parts' in payload:
                anexos_baixados = leitor_gmail.baixar_anexos(servico_gmail, msg_id, payload['parts'])
                
                if regras_yara and anexos_baixados:
                    todas_ameacas = []
                    for anexo in anexos_baixados:
                        caminho_arquivo = anexo["caminho_local"]
                        tipo = anexo["tipo"]
                        
                        # NOVO: Puxa o resultado do OCR que o leitor_gmail fez!
                        ameaca_ocr = anexo.get("ameaca_ocr", False)
                        if ameaca_ocr:
                            todas_ameacas.append("DetectarPhishingPorImagem")
                        
                        if os.path.exists(caminho_arquivo):
                            # Binário (YARA)
                            for m in regras_yara.match(caminho_arquivo): 
                                se_nao_existe = m.rule not in todas_ameacas
                                if se_nao_existe:
                                    todas_ameacas.append(m.rule)
                            
                            # Extração de texto (PDF/OCR secundário)
                            texto_extraido = ""
                            if tipo == "application/pdf":
                                try:
                                    leitor = PdfReader(caminho_arquivo)
                                    for pagina in leitor.pages: texto_extraido += pagina.extract_text() + "\n"
                                except: pass
                            
                            # YARA no texto extraído do PDF
                            if texto_extraido.strip():
                                caminho_txt = caminho_arquivo + ".txt"
                                with open(caminho_txt, "w", encoding="utf-8") as f: f.write(texto_extraido)
                                for m in regras_yara.match(caminho_txt):
                                    if m.rule not in todas_ameacas: todas_ameacas.append(m.rule)
                                os.remove(caminho_txt)

                    # SE ENCONTROU AMEAÇA, O CÃO DE GUARDA ATACA!
                    if todas_ameacas:
                        ameacas_formatadas = [{"arquivo": "Anexo Verificado", "regra_acionada": r} for r in todas_ameacas]
                        
                        dados_relatorio = {
                            "id_email": msg_id,
                            "remetente": remetente,
                            "assunto": assunto,
                            "ameacas_yara": ameacas_formatadas,
                            "explicacao_humana": gerar_relatorio_humano(ameacas_formatadas)
                        }
                        
                        # 1. Tira do INBOX e joga no SPAM
                        sucesso_neutralizacao = neutralizar_email(msg_id)
                        if sucesso_neutralizacao:
                            # 2. Salva no banco de dados do Dashboard
                            salvar_ameaca_no_db(dados_relatorio)
                            ameacas_neutralizadas_agora += 1

    return {
        "status": "Patrulha Concluída",
        "verificados": len(mensagens),
        "neutralizados_agora": ameacas_neutralizadas_agora
    }