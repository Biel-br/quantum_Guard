import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/hash_controller.dart';

class HashView extends StatefulWidget {
  const HashView({super.key});

  @override
  State<HashView> createState() => _HashViewState();
}

class _HashViewState extends State<HashView> {
  final ctrl = GetIt.I.get<HashController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hash Scanner', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(  // ← adicione esse Center
       child: Padding(
         padding: const EdgeInsets.all(24),
         child: Column(
          mainAxisSize: MainAxisSize.min, // ← adicione isso
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícone de status
            Icon(
              ctrl.escaneado
                ? (ctrl.ameaca ? Icons.warning_amber : Icons.shield)
                : Icons.shield_outlined,
              size: 100,
              color: ctrl.escaneado
                ? (ctrl.ameaca ? Colors.red : Colors.green)
                : Colors.grey,
            ),

            const SizedBox(height: 24),

            // Status
            Text(
              ctrl.status.isEmpty ? 'Nenhum arquivo escaneado' : ctrl.status,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: ctrl.ameaca ? Colors.red : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Nome do arquivo
            if (ctrl.nomeArquivo.isNotEmpty)
              Text(
                '📄 ${ctrl.nomeArquivo}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 8),

            // Hash gerado
            if (ctrl.hash.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SHA256:\n${ctrl.hash}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 40),

            // Botão escanear
            ctrl.carregando
  ? const CircularProgressIndicator()
  : ElevatedButton.icon(
      icon: const Icon(Icons.folder_open),
      label: const Text('Selecionar Arquivo'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
      ),
      onPressed: () async {
        await ctrl.selecionarEscanear();
        if (mounted && ctrl.escaneado) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ctrl.status),
              backgroundColor: ctrl.ameaca ? Colors.red : Colors.green,
            ),
          );
        }
      },
    ),
const SizedBox(height: 12),

            // Botão limpar
            if (ctrl.escaneado)
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar'),
                onPressed: ctrl.limpar,
              ),
          ],
         ),
        ),
      ),
    );
  }
}
