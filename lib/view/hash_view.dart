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
  final _manualEC = TextEditingController(); // ⬅️ Controlador de texto adicionado

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _manualEC.dispose(); // ⬅️ Previne vazamento de memória
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hash Scanner', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView( // ⬅️ Permite rolar a tela quando o teclado sobe
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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

              if (ctrl.nomeArquivo.isNotEmpty)
                Text(
                  '📄 ${ctrl.nomeArquivo}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 8),

              if (ctrl.hash.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText( // ⬅️ Usando SelectableText para permitir que você copie o hash gerado
                    'SHA256:\n${ctrl.hash}',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 40),

              ctrl.carregando
                ? const CircularProgressIndicator()
                : Column( // ⬅️ Aqui os botões foram expandidos
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Selecionar Arquivo Físico'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          await ctrl.selecionarEscanear();
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      const Text("OU", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _manualEC,
                        decoration: InputDecoration(
                          hintText: 'Cole um Hash SHA-256 aqui...',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: Colors.blue),
                            onPressed: () async {
                              FocusScope.of(context).unfocus(); // Recolhe o teclado
                              await ctrl.escanearHashManual(_manualEC.text);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

              const SizedBox(height: 12),

              if (ctrl.escaneado)
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Limpar'),
                  onPressed: () {
                    _manualEC.clear(); // Limpa a barra de texto junto
                    ctrl.limpar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}