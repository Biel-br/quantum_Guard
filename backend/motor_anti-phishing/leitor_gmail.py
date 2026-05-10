import os
import base64
from bs4 import BeautifulSoup
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/gmail.modify']
ALLOWLIST_DOMINIOS = ['duolingo.com', 'twitch.tv', 'github.com', 'linkedin.com']

# Cria a pasta para salvar os anexos se ela não existir
PASTA_ANEXOS = "anexos_suspeitos"
if not os.path.exists(PASTA_ANEXOS):
    os.makedirs(PASTA_ANEXOS)

def autenticar_gmail():
    creds = None
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_file('token.json', SCOPES)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
    return build('gmail', 'v1', credentials=creds)

def extrair_partes_email(parts):
    texto_puro = ""
    html = ""
    for part in parts:
        mime_type = part.get('mimeType')
        data = part.get('body', {}).get('data')
        
        if mime_type == 'text/plain' and data:
            texto_puro += base64.urlsafe_b64decode(data).decode('utf-8', errors='ignore')
        elif mime_type == 'text/html' and data:
            html += base64.urlsafe_b64decode(data).decode('utf-8', errors='ignore')
        elif 'parts' in part:
            sub_texto, sub_html = extrair_partes_email(part['parts'])
            texto_puro += sub_texto
            html += sub_html
    return texto_puro, html

def extrair_links(html):
    if not html:
        return []
    soup = BeautifulSoup(html, 'lxml')
    links = [tag_a['href'] for tag_a in soup.find_all('a', href=True)]
    return list(set(links))

def baixar_anexos(servico, msg_id, parts):
    """Procura por anexos, faz o download e salva na pasta local."""
    anexos_baixados = []
    
    for part in parts:
        filename = part.get('filename')
        mime_type = part.get('mimeType')
        
        # Se tem nome de arquivo e um ID de anexo, é um arquivo!
        if filename and part.get('body') and 'attachmentId' in part['body']:
            attachment_id = part['body']['attachmentId']
            
            # Pede o arquivo completo para a API do Gmail
            anexo_obj = servico.users().messages().attachments().get(
                userId='me', messageId=msg_id, id=attachment_id
            ).execute()
            
            file_data = base64.urlsafe_b64decode(anexo_obj['data'])
            
            # Salva o arquivo na pasta com o ID da mensagem na frente para não sobrescrever arquivos com mesmo nome
            caminho_arquivo = os.path.join(PASTA_ANEXOS, f"{msg_id}_{filename}")
            
            with open(caminho_arquivo, 'wb') as f:
                f.write(file_data)
                
            anexos_baixados.append({
                "nome_arquivo": filename,
                "caminho_local": caminho_arquivo,
                "tipo": mime_type,
                "tamanho_bytes": len(file_data)
            })
            
        # Tratamento de e-mails complexos (recursão)
        elif 'parts' in part:
            anexos_baixados.extend(baixar_anexos(servico, msg_id, part['parts']))
            
    return anexos_baixados

def analisar_autenticacao(headers):
    auth_results = ""
    for header in headers:
        if header['name'].lower() == 'authentication-results':
            auth_results = header['value'].lower()
            break

    spf_pass = 'spf=pass' in auth_results
    dkim_pass = 'dkim=pass' in auth_results
    dmarc_pass = 'dmarc=pass' in auth_results
    return spf_pass, dkim_pass, dmarc_pass

def extrair_dominio(remetente):
    if '@' in remetente:
        return remetente.split('@')[-1].replace('>', '').strip()
    return ""