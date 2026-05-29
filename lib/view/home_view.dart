import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Suas Views
import 'hash_view.dart';
import 'url_view.dart'; // ⬅️ IMPORT DA TELA DE URL ADICIONADO
import 'cofre_view.dart';
import 'relatorio_view.dart';
import 'sobre_view.dart';
import 'login_view.dart';
import 'perfil_view.dart';
import 'search_view.dart' as minha_pesquisa;

// Controllers e Services
import '../service/notificacao_service.dart';
import '../service/auth_service.dart'; // ⬅️ IMPORT DO SERVICE CORRETO

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    _iniciarVigilanteDeAmeacas();
  }

  void _iniciarVigilanteDeAmeacas() {
    FirebaseFirestore.instance.collection('logs_seguranca').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          NotificacaoService.mostrarAlertaAmeaca(
            "🚨 Nova Ameaça Bloqueada!",
            "Verifique o painel. Assunto: ${change.doc['assunto'] ?? 'Desconhecido'}",
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final funcionalidades = [
      {
        'titulo': 'Hash Scanner',
        'icone': Icons.search,
        'cor': Colors.blue,
        'tela': const HashView(),
      },
      {
        'titulo': 'Verificador de URL', // ⬅️ VOLTOU PARA A TELA!
        'icone': Icons.link,
        'cor': Colors.purple,
        'tela': const UrlView(), // Verifique se o nome da sua classe é exatamente UrlView
      },
      {
        'titulo': 'Meu Perfil',
        'icone': Icons.person,
        'cor': Colors.deepOrange,
        'tela': const PerfilView(),
      },
      {
        'titulo': 'Pesquisa Avançada',
        'icone': Icons.manage_search,
        'cor': Colors.indigo,
        'tela': const minha_pesquisa.SearchView(),
      },
      {
        'titulo': 'Cofre de Senhas',
        'icone': Icons.lock,
        'cor': Colors.green,
        'tela': const CofreView(),
      },
      {
        'titulo': 'Relatórios',
        'icone': Icons.description,
        'cor': Colors.red,
        'tela': const RelatorioView(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quantum Guard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Sobre',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SobreView()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair do app?'),
                  content: const Text('Deseja realmente sair?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
  // Salva o navegador antes de qualquer operação assíncrona (Evita o erro de context do Flutter)
  final navigator = Navigator.of(context);
  
  // 1. Tira o pop-up da tela
  navigator.pop(); 
  
  // 2. Faz o logout ignorando qualquer erro silencioso
  try {
    await AuthService().logout();
  } catch (e) {
    print('Erro ignorado no logout: $e');
  }
  
  // 3. Joga para a tela de login
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginView()),
    (Route<dynamic> route) => false,
  );
},
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: funcionalidades.length,
          itemBuilder: (context, index) {
            final item = funcionalidades[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item['tela'] as Widget),
              ),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icone'] as IconData,
                      size: 42,
                      color: item['cor'] as Color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['titulo'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}