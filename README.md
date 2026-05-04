# Quantum Guard

Aplicativo multiplataforma de segurança digital desenvolvido em **Flutter/Dart**, com foco em proteção de arquivos, senhas e navegação segura.

---

## Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Padrão de Arquitetura](#padrão-de-arquitetura)
- [Funcionalidades](#funcionalidades)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Como Executar](#como-executar)
- [Assets](#assets)

---

## Sobre o Projeto

O Quantum Guard  é um aplicativo de segurança digital que oferece ferramentas simples para proteger o usuário contra ameaças digitais. O projeto foi desenvolvido como trabalho prático da disciplina de Programação para Dispositivos Móveis, utilizando Flutter SDK com gerenciamento de estado via `ChangeNotifier` e persistência local com `SharedPreferences`.

---

## Estrutura de Pastas

```
projeto_pdm/
│
├── assets/                          # Arquivos estáticos
│   ├── logo.png                     # Logotipo da aplicação
│   ├── hashes_maliciosos.json       # Base de hashes para comparação
│   └── urls_maliciosas.json         # Base de URLs maliciosas
│
├── lib/
│   ├── main.dart                    # Ponto de entrada + registro do GetIt
│   │
│   ├── view/                        # Camada de interface (UI)
│   │   ├── login_view.dart          # Tela de autenticação
│   │   ├── cadastro_view.dart       # Tela de cadastro de usuário
│   │   ├── esqueceu_senha_view.dart # Tela de recuperação de senha
│   │   ├── home_view.dart           # Tela principal com os 5 cards
│   │   ├── hash_view.dart           # Verificador de hash
│   │   ├── cofre_view.dart          # Cofre de senhas
│   │   ├── url_view.dart            # Verificador de URLs
│   │   ├── extensao_view.dart       # Verificador de extensões
│   │   ├── relatorio_view.dart      # Relatório de segurança
│   │   └── sobre_view.dart          # Informações sobre o projeto
│   │
│   ├── controller/                  # Camada de estado (ponte entre View e Service)
│   │   ├── auth_controller.dart     # Estado de autenticação
│   │   ├── hash_controller.dart     # Estado do hash scanner
│   │   ├── cofre_controller.dart    # Estado do cofre de senhas
│   │   ├── url_controller.dart      # Estado do verificador de URLs
│   │   ├── extensao_controller.dart # Estado do verificador de extensões
│   │   └── relatorio_controller.dart# Estado do relatório
│   │
│   └── service/                     # Camada de lógica (regras de negócio)
│       ├── auth_service.dart        # Lógica de autenticação
│       ├── hash_service.dart        # Lógica de geração e verificação de hash
│       ├── cofre_service.dart       # Lógica de criptografia de senhas
│       ├── url_service.dart         # Lógica de verificação de URLs
│       ├── extensao_service.dart    # Lógica de verificação de extensões
│       └── relatorio_service.dart   # Lógica de persistência do relatório
│
├── web/
│   └── index.html                   # Configuração para Flutter Web
│
└── pubspec.yaml                     # Dependências e assets do projeto
```

---

## Padrão de Arquitetura

O projeto segue o padrão **MVC (Model-View-Controller)** adaptado para Flutter, dividido em 3 camadas:

```
VIEW  →  CONTROLLER  →  SERVICE
(tela)   (ponte/estado)  (lógica)
```

### View
Responsável apenas por exibir dados e capturar ações do usuário. Nunca contém lógica de negócio.

```dart
ElevatedButton(
  onPressed: () => ctrl.login(), // apenas chama o controller
)
```

### Controller
Faz a ponte entre a View e o Service. Gerencia o estado da interface usando `ChangeNotifier` — cada `notifyListeners()` redesenha automaticamente as telas que dependem desse controller.

```dart
class HashController extends ChangeNotifier {
  bool carregando = false;
  String status = '';

  Future<void> selecionarEscanear() async {
    carregando = true;
    notifyListeners(); // avisa a tela para redesenhar

    final resultado = await _service.verificarHash(hash);
    status = resultado ? '⚠️ Ameaça!' : '✅ Limpo';

    carregando = false;
    notifyListeners(); // avisa novamente com o resultado
  }
}
```

### Service
Contém toda a lógica de negócio pura, sem conhecer nada da interface. Isso permite que no futuro a lógica seja migrada para um backend real (ex: Rust + Actix) sem alterar a View ou o Controller.

```dart
class HashService {
  String gerarHash(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verificarHash(String hash) async {
    final lista = await carregarHashesMaliciosos();
    return lista.contains(hash);
  }
}
```

### Injeção de Dependência — GetIt
Os controllers são registrados como singletons no `main.dart` via `GetIt`, garantindo que exista apenas uma instância de cada controller durante toda a execução do app.

```dart
void _setupGetIt() {
  GetIt.I.registerSingleton(RelatorioController()); // primeiro!
  GetIt.I.registerSingleton(HashController());
  GetIt.I.registerSingleton(CofreController());
  GetIt.I.registerSingleton(UrlController());
  GetIt.I.registerSingleton(ExtensaoController());
  GetIt.I.registerSingleton(AuthController());
}
```

> ⚠️ O `RelatorioController` deve ser registrado primeiro pois os demais controllers dependem dele para salvar o histórico.

---

##  Funcionalidades

### Autenticação (RF001, RF002, RF003)
| Tela | Descrição |
| **Login** | Autenticação com validação de email e senha |
| **Cadastro** | Registro com nome, email, telefone, senha e confirmação |
| **Esqueceu a Senha** | Recuperação simulada via email cadastrado |

Os dados de usuários são persistidos localmente via `SharedPreferences` em formato JSON.

### Funcionalidades Específicas 
| Funcionalidade | Descrição |
| **Hash Scanner** | Gera SHA256 do arquivo e compara com base de hashes maliciosos |
| **Cofre de Senhas** | Armazena senhas criptografadas com AES via Base64 |
| **Verificador de URLs** | Compara domínios com lista local de URLs maliciosas |
| **Verificador de Extensões** | Detecta arquivos com extensões perigosas (.exe, .bat, .vbs...) |
| **Relatório de Segurança** | Histórico de todos os scans realizados com filtros |

### Outras Telas (RF004)
- **Sobre** — Informações institucionais, equipe e tecnologias utilizadas

---

##  Tecnologias Utilizadas

| Tecnologia | Uso |
|---|---|
| **Flutter SDK** | Framework principal |
| **Dart** | Linguagem de programação |
| **GetIt** | Injeção de dependência |
| **SharedPreferences** | Persistência local de dados |
| **Crypto** | Geração de hash SHA256 |
| **FilePicker** | Seleção de arquivos do dispositivo |
| **Encrypt** | Criptografia de senhas (AES) |

---

## Como Executar

### Pré-requisitos
- Flutter SDK instalado
- Navegador Chrome ou Firefox

### Passos

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/projeto_pdm.git

# Entre na pasta
cd projeto_pdm

# Instale as dependências
flutter pub get

# Execute no navegador
flutter run -d web-server
```

Acesse `http://localhost:<porta>` no navegador.

---

## Assets

Os assets são arquivos estáticos empacotados junto com o app e declarados no `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/logo.png
    - assets/hashes_maliciosos.json
    - assets/urls_maliciosas.json
```

| Asset | Tipo | Descrição |
| `logo.png` | Imagem | Logotipo exibido na tela de login |
| `hashes_maliciosos.json` | JSON | Lista de hashes SHA256 maliciosos para comparação |
| `urls_maliciosas.json` | JSON | Lista de domínios maliciosos para comparação |

---

## Equipe
 Gabriel Reis - Desenvolvedor
 Felipe Delchiaro - Desenvolvedor 

---

## Informações Institucionais

- Disciplina: Programação para Dispositivos Móveis
- Instituição: Fatec RP
- Professor: Rodrigo Plotze
- Versão: 1.0.0