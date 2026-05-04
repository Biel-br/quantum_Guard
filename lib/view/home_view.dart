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
import '../controller/auth_controller.dart';
import '../controller/monitor_controller.dart';
import 'monitor_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final monitorCtrl = GetIt.I.get<MonitorController>();

  @override
  void initState() {
    super.initState();
    monitorCtrl.addListener(() => setState(() {}));
    monitorCtrl.iniciar();
  }

  @override
  void dispose() {
    monitorCtrl.parar();
    super.dispose();
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
        'titulo': 'Relatório',
        'icone': Icons.description,
        'cor': Colors.red,
        'tela': const RelatorioView(),
      },
      {
        'titulo': 'YARA Scanner',
        'icone': Icons.policy,
        'cor': Colors.deepOrange,
        'tela': const YaraView(),
      },
      {
        'titulo': 'Monitor',
        'icone': Icons.monitor_heart,
        'cor': Colors.teal,
        'tela': const MonitorView(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AntiVirus App',
          style: TextStyle(color: Colors.white),
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

          // Grid de funcionalidades
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
                      elevation: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icone'] as IconData,
                            size: 48,
                            color: item['cor'] as Color,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['titulo'] as String,
                            style: const TextStyle(
                              fontSize: 16,
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

          // Painel do sistema
          Expanded(
            flex: 3,
            child: _buildPainelSistema(),
          ),
        ],
      ),
    );
  }

  Widget _buildPainelSistema() {
    if (monitorCtrl.carregando && monitorCtrl.info == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (monitorCtrl.info == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text(
              'Backend offline\nInicie o servidor Rust',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Título
          Row(
            children: [
              Icon(Icons.monitor_heart, color: Colors.blue.shade900),
              const SizedBox(width: 8),
              Text(
                'Monitor do Sistema',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const Spacer(),
              Text(
                '${monitorCtrl.hostname} • ${monitorCtrl.nomeOS}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Cards de resumo
          Row(
            children: [
              _buildCardInfo(
                'Memória',
                '${monitorCtrl.memoriaUsada.toStringAsFixed(1)}GB / '
                '${monitorCtrl.memoriaTotal.toStringAsFixed(1)}GB',
                monitorCtrl.usoMemoria / 100,
                Icons.memory,
                monitorCtrl.usoMemoria > 80 ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildCardInfo(
                'Processos',
                '${monitorCtrl.totalProcessos} total',
                null,
                Icons.settings_applications,
                Colors.purple,
              ),
              const SizedBox(width: 8),
              _buildCardInfo(
                'Suspeitos',
                '${monitorCtrl.processosSuspeitos} encontrados',
                null,
                Icons.warning_amber,
                monitorCtrl.processosSuspeitos > 0
                  ? Colors.red
                  : Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Top processos
          const Text(
            'Top Processos (por memória)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...monitorCtrl.processos
            .take(5)
            .map((p) => _buildProcessoItem(p)),

          // Discos
          if (monitorCtrl.discos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Discos',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...monitorCtrl.discos.map((d) => _buildDiscoItem(d)),
          ],
        ],
      ),
    );
  }

  Widget _buildCardInfo(
    String label,
    String valor,
    double? progresso,
    IconData icone,
    Color cor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: 16),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(color: cor, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: cor,
              ),
            ),
            if (progresso != null) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progresso,
                backgroundColor: cor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(cor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProcessoItem(dynamic p) {
    final suspeito = p['suspeito'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: suspeito ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: suspeito ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            suspeito ? Icons.warning_amber : Icons.circle,
            size: 12,
            color: suspeito ? Colors.red : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              p['nome'] ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: suspeito
                  ? FontWeight.bold
                  : FontWeight.normal,
                color: suspeito ? Colors.red : Colors.black87,
              ),
            ),
          ),
          Text(
            '${(p['memoria_mb'] ?? 0.0).toStringAsFixed(0)} MB',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoItem(dynamic d) {
    final uso = (d['uso_percent'] ?? 0.0).toDouble();
    final cor = uso > 90
      ? Colors.red
      : uso > 70
        ? Colors.orange
        : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, size: 14, color: cor),
              const SizedBox(width: 6),
              Text(
                d['nome'] ?? '',
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${(d['disponivel_gb'] ?? 0.0).toStringAsFixed(1)}GB livre',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: uso / 100,
            backgroundColor: cor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(cor),
          ),
        ],
      ),
    );
  }
}