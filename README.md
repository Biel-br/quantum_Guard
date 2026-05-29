# Quantum Guard

Aplicativo multiplataforma de segurança digital desenvolvido em **Flutter/Dart** com backend serveless utilizando **Firebase** e **Python**. O foco principal é a proteção de arquivos, gerenciamento seguro de senhas e integração com inteligência global contra ameaças.

---

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Funcionalidades e Requisitos (RF)](#funcionalidades-e-requisitos-rf)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Padrão de Arquitetura](#padrão-de-arquitetura)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Como Executar](#como-executar)
- [Equipe](#equipe)

---

## 🎯 Sobre o Projeto

O **Quantum Guard** é uma solução de segurança digital criada para proteger usuários contra ameaças digitais de forma simplificada. Desenvolvido como trabalho prático da disciplina de Programação para Dispositivos Móveis, o projeto evoluiu de uma persistência local para uma arquitetura robusta em nuvem. 

O sistema conta com autenticação segura, banco de dados em tempo real (Firestore), consumo de APIs públicas de cibersegurança e uma arquitetura em microsserviços com automação via Google Cloud Functions.

---

## 🚀 Funcionalidades e Requisitos (RF)

O aplicativo foi arquitetado para cumprir e superar os requisitos propostos na disciplina:

* **[RF001 / RF002] Autenticação e Registro Seguros**
    * Login e criação de contas validados via **Firebase Authentication**.
    * Recuperação de senha via e-mail.
    * Coleta de dados adicionais no cadastro (Nome, Telefone, Plano) salvos de forma vinculada ao UID.
    * Validação de força de senha via Regex.

* **[RF003] Inserção e Segregação de Dados**
    * Dados distribuídos em **4 coleções distintas** no Firestore (`usuarios`, `cofre_senhas`, `hashes_verificados`, `relatorio`).
    * Uso de regras de segurança rigorosas (`Firestore Rules`): os dados são isolados por usuário utilizando verificação de token e UID.

* **[RF004] Atualização de Dados**
    * Edição de informações pessoais na tela de **Meu Perfil**.
    * Atualização e regravação de senhas criptografadas previamente salvas no **Cofre de Senhas**.

* **[RF005] Recuperação de Dados em Tempo Real**
    * Uso contínuo de `StreamBuilder` e `ListView.builder` em duas áreas principais do app: **Relatório de Scans** e **Cofre de Senhas**, garantindo que qualquer alteração na nuvem reflita instantaneamente na interface visual.

* **[RF006] Pesquisa Avançada**
    * Tela exclusiva para pesquisa do histórico de verificações.
    * Filtros reativos instantâneos (sem diferenciação de maiúsculas/minúsculas).
    * Ordenação temporal (Mais recentes/antigos) e alfabética (A-Z).

* **[RF007] Consumo de API Externa**
    * O recurso **Hash Scanner** consome a API pública do **VirusTotal** via pacote `http`, enviando artefatos digitais para análise global e retornando relatórios de ameaças em tempo real.

* **[Extra] Cloud Functions (Backend em Python)**
    * Rotinas em nuvem construídas em Python (Motor Anti-Phishing) operando no Google Cloud Functions.

---

## 📁 Estrutura de Pastas

A organização do código separa claramente o Front-end (Flutter) do Back-end (Python Cloud Functions).

```text
projeto_pdm/
│
├── functions/                       # Backend Cloud (Python)
│   ├── main.py                      # Motor de inspeção e Cloud Functions
│   └── requirements.txt             # Dependências do Python
│
├── lib/                             # Aplicação Flutter
│   ├── main.dart                    # Ponto de entrada + Firebase Init
│   │
│   ├── view/                        # Camada de interface (UI)
│   │   ├── login_view.dart          # Tela de autenticação
│   │   ├── cadastro_view.dart       # Tela de registro e Regex
│   │   ├── home_view.dart           # Dashboard central
│   │   ├── hash_view.dart           # Verificador via VirusTotal API
│   │   ├── url_view.dart            # Verificador de domínios
│   │   ├── cofre_view.dart          # Cofre de senhas com StreamBuilder
│   │   ├── perfil_view.dart         # Edição de dados do usuário
│   │   ├── search_view.dart         # Pesquisa e ordenação (RF006)
│   │   └── relatorio_view.dart      # Relatório consolidado em tempo real
│   │
│   ├── controller/                  # Camada de estado (ChangeNotifier)
│   │   ├── auth_controller.dart     
│   │   ├── hash_controller.dart     
│   │   ├── url_controller.dart      
│   │   └── relatorio_controller.dart
│   │
│   └── service/                     # Regras de Negócio e APIs
│       ├── auth_service.dart        # Integração com Firebase Auth
│       ├── url_service.dart         
│       └── notificacao_service.dart # Exibição de alertas e SnackBars
│
└── pubspec.yaml                     # Dependências do Flutter

```

---

## 🏛 Padrão de Arquitetura

O projeto segue um padrão **MVC** (Model-View-Controller) simplificado para aplicações declarativas:

* **View:** Contém exclusivamente componentes visuais (Widgets). Nenhuma regra de negócio reside aqui. A interface reage às mudanças de estado.
* **Controller (`ChangeNotifier`):** Atua como maestro da tela. Recebe inputs da View, dispara o processamento no Service e notifica a View (`notifyListeners()`) para se reconstruir quando os dados chegam ou alteram.
* **Service:** Comunicação pura com o mundo exterior. Consultas ao Firestore, requisições HTTP para a API do VirusTotal e comunicação com o Firebase Authentication ocorrem nesta camada.

---

## 🛠 Tecnologias Utilizadas

### Front-end

* **Flutter SDK & Dart** — Framework principal.
* **Provider / ChangeNotifier** — Gerenciamento de estado nativo.
* **HTTP** — Consumo de APIs REST (VirusTotal).

### Back-end & Infraestrutura

* **Firebase Authentication** — Gestão de identidade e segurança de tokens.
* **Cloud Firestore** — Banco de dados NoSQL reativo.
* **Google Cloud Functions** — Serveless computing.
* **Python 3.12** — Linguagem utilizada nas rotinas de nuvem.
* **Secret Manager (GCP)** — Armazenamento seguro de chaves de API e credenciais OAuth.

---

## ⚙️ Como Executar

### Pré-requisitos

* Flutter SDK instalado e configurado na máquina.
* Navegador Web (Chrome/Edge) para debug web, ou emulador Android/iOS.
* *Nota:* As variáveis do Firebase (`firebase_options.dart`) já devem estar geradas via FlutterFire CLI.

### Passos

```bash
# Clone o repositório
git clone [https://github.com/seu-usuario/projeto_pdm.git](https://github.com/seu-usuario/projeto_pdm.git)

# Entre na pasta
cd projeto_pdm

# Instale as dependências
flutter pub get

# Execute a aplicação no Google Chrome
flutter run -d chrome

```

Para realizar o deploy em produção no Firebase Hosting:

```bash
flutter build web
firebase deploy --only hosting

```

---

## 👥 Equipe e Instituição

* **Gabriel Reis de Souza** — Desenvolvedor
* **Felipe Delchiaro** — Desenvolvedor

**Informações Institucionais:**

* **Instituição:** Fatec Ribeirão Preto
* **Curso:** Análise e Desenvolvimento de Sistemas
* **Disciplina:** Programação para Dispositivos Móveis
* **Professor:** Rodrigo Plotze
* **Versão:** 1.0.0

```

```