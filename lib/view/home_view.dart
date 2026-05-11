import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:projeto_pdm/view/yara_view.dart';
import 'hash_view.dart';
import 'cofre_view.dart';
import 'url_view.dart';
import 'extensao_view.dart';
import 'relatorio_view.dart';
import 'sobre_view.dart';
import 'login_view.dart';
import 'email_view.dart'; 
import '../controller/auth_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/notificacao_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  
  // ----------------------------------------------------
  // COLE O CÓDIGO AQUI PARA DENTRO (ANTES DO BUILD!)
  // ----------------------------------------------------
  @override
  void initState() {
    super.initState();
    _iniciarVigilanteDeAmeacas();
  }

  void _iniciarVigilanteDeAmeacas() {
    // Fica escutando a coleção em tempo real
    FirebaseFirestore.instance.collection('logs_seguranca').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        // Se um documento NOVO for adicionado ao banco
        if (change.type == DocumentChangeType.added) {
          
          // Dispara a notificação no celular
          NotificacaoService.mostrarAlertaAmeaca(
            "🚨 Nova Ameaça Bloqueada!",
            "Verifique o painel. Assunto: ${change.doc['assunto'] ?? 'Desconhecido'}",
          );
        }
      }
    });
  }
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Lista limpa, sem o Monitor
    final funcionalidades = [
      {
        'titulo': 'Hash Scanner',
        'icone': Icons.search,
        'cor': Colors.blue,
        'tela': const HashView(),
      },
      {
        'titulo': 'Cofre de Senhas',
        'icone': Icons.lock,
        'cor': Colors.green,
        'tela': const CofreView(),
      },
      {
        'titulo': 'Verificador de URLs',
        'icone': Icons.link,
        'cor': Colors.orange,
        'tela': const UrlView(),
      },
      {
        'titulo': 'Verificador de Extensões',
        'icone': Icons.folder,
        'cor': Colors.purple,
        'tela': const ExtensaoView(),
      },
      {
        'titulo': 'YARA Scanner',
        'icone': Icons.policy,
        'cor': Colors.deepOrange,
        'tela': const YaraView(),
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
                        final ctrl = GetIt.I.get<AuthController>();
                        await ctrl.logout();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginView(),
                            ),
                          );
                        }
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
      body: Column(
        children: [
          // 1. DESTAQUE: Caixa de Entrada Protegida
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blue.shade900.withOpacity(0.3), width: 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmailView()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mark_email_read,
                          size: 36,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Caixa de Entrada",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Escanear e-mails contra Phishing e Malware",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. GRID DAS OUTRAS FERRAMENTAS
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1, // Deixa os cards um pouco mais retangulares
                ),
                itemCount: funcionalidades.length,
                itemBuilder: (context, index) {
                  final item = funcionalidades[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => item['tela'] as Widget,
                      ),
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
          ),
        ],
      ),
    );
  }
}