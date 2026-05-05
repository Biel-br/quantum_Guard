from fastapi import FastAPI
import leitor_gmail

app = FastAPI(
    title="Quantum Guard - Anti-Phishing Engine",
    description="API para análise e pontuação de risco de e-mails",
    version="1.0"
)

servico_gmail = leitor_gmail.autenticar_gmail()

@app.get("/")
def home():
    return {"status": "Motor Quantum Guard online e operando!"}

@app.get("/api/v1/analisar-emails")
def analisar_emails_api(quantidade: int = 3):
    resultados = servico_gmail.users().messages().list(userId='me', labelIds=['INBOX'], maxResults=quantidade).execute()
    mensagens = resultados.get('messages', [])

    if not mensagens:
        return {"analises": [], "mensagem": "Nenhum e-mail encontrado na caixa de entrada."}

    lista_analises = []

    for msg in mensagens:
        msg_id = msg['id']
        email_completo = servico_gmail.users().messages().get(userId='me', id=msg_id, format='full').execute()
        payload = email_completo['payload']
        headers = payload.get('headers', [])
        
        assunto = "Sem Assunto"
        remetente = "Desconhecido"
        
        for header in headers:
            if header['name'] == 'Subject':
                assunto = header['value']
            if header['name'] == 'From':
                remetente = header['value']

        dominio = leitor_gmail.extrair_dominio(remetente)
        spf, dkim, dmarc = leitor_gmail.analisar_autenticacao(headers)
        
        resultado_email = {
            "id": msg_id,
            "remetente": remetente,
            "dominio": dominio,
            "assunto": assunto,
            "autenticacao": {
                "spf_pass": spf,
                "dkim_pass": dkim,
                "dmarc_pass": dmarc
            },
            "acao_tomada": "",
            "links_extraidos": [],
            "anexos": [] # NOVO CAMPO PARA OS ANEXOS
        }

        # Lógica de Triagem Rápida
        if dominio in leitor_gmail.ALLOWLIST_DOMINIOS and spf and dkim and dmarc:
            resultado_email["acao_tomada"] = "FAST_PATH"
            resultado_email["risco"] = "Baixo"
        else:
            resultado_email["acao_tomada"] = "DEEP_SCAN"
            resultado_email["risco"] = "Em processamento..."
            
            texto_puro = ""
            html = ""
            
            # Se o e-mail tem partes (HTML + Texto + Anexos)
            if 'parts' in payload:
                # 1. Extrai o texto e HTML
                texto_puro, html = leitor_gmail.extrair_partes_email(payload['parts'])
                # 2. Baixa os anexos (NOVO)
                resultado_email["anexos"] = leitor_gmail.baixar_anexos(servico_gmail, msg_id, payload['parts'])
            else:
                if payload['mimeType'] == 'text/html':
                    html = leitor_gmail.base64.urlsafe_b64decode(payload['body']['data']).decode('utf-8', errors='ignore')
            
            resultado_email["links_extraidos"] = leitor_gmail.extrair_links(html)

        lista_analises.append(resultado_email)

    return {"analises": lista_analises}