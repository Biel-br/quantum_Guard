import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/yara_controller.dart';

class YaraView extends StatefulWidget {
  const YaraView({super.key});

  @override
  State<YaraView> createState() => _YaraViewState();
}

class _YaraViewState extends State<YaraView> {
  final ctrl = GetIt.I.get<YaraController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YARA Scanner', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (ctrl.escaneado)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Limpar',
              onPressed: ctrl.limpar,
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Ícone de status
              Icon(
                ctrl.escaneado
                  ? (ctrl.ameaca ? Icons.policy : Icons.verified_user)
                  : Icons.policy_outlined,
                size: 100,
                color: ctrl.escaneado
                  ? (ctrl.ameaca ? Colors.red : Colors.green)
                  : Colors.grey,
              ),

              const SizedBox(height: 20),

              // Status
              Text(
                ctrl.status.isEmpty
                  ? 'Nenhum arquivo escaneado'
                  : ctrl.status,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ctrl.ameaca ? Colors.red : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Nome do arquivo
              if (ctrl.nomeArquivo.isNotEmpty)
                Text(
                  '📄 ${ctrl.nomeArquivo}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 16),

              // Lista de matches encontrados
              if (ctrl.matches.isNotEmpty) ...[
                const Text(
                  'Regras acionadas:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...ctrl.matches.map((match) => _buildMatchCard(match)),
              ],

              const SizedBox(height: 32),

              // Botão escanear
              ctrl.carregando
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Selecionar Arquivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await ctrl.selecionarEscanear();
                      if (mounted && ctrl.escaneado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ctrl.status),
                            backgroundColor: ctrl.ameaca
                              ? Colors.red
                              : Colors.green,
                          ),
                        );
                      }
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // Card de cada regra acionada
  Widget _buildMatchCard(dynamic match) {
    final severidade = match['severidade'] ?? 'desconhecida';
    final cor = severidade == 'alta'
      ? Colors.red
      : severidade == 'media'
        ? Colors.orange
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cor.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: cor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match['regra'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    match['descricao'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                severidade.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}