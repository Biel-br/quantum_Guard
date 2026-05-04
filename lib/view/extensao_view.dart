import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/extensao_controller.dart';

class ExtensaoView extends StatefulWidget {
  const ExtensaoView({super.key});

  @override
  State<ExtensaoView> createState() => _ExtensaoViewState();
}

class _ExtensaoViewState extends State<ExtensaoView> {
  final ctrl = GetIt.I.get<ExtensaoController>();

  @override
  void initState() {
  super.initState();
  ctrl.addListener(() => setState(() {}));
  ctrl.carregar(); //carrega o histórico salvo
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificador de Extensões', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (ctrl.verificado)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: ctrl.limpar,
              tooltip: 'Limpar',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [

            // Botão selecionar
            SizedBox(
              width: double.infinity,
              child: ctrl.carregando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Selecionar Arquivos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await ctrl.selecionarEVerificar();
                      if (mounted && ctrl.verificado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${ctrl.totalArquivos} arquivo(s) verificado(s) — '
                              '${ctrl.totalPerigosos} perigoso(s) encontrado(s)'
                            ),
                            backgroundColor: ctrl.totalPerigosos > 0
                              ? Colors.red
                            : Colors.green,
                          ),
                        );
                      }
                    },
                  ),
            ),

            const SizedBox(height: 24),

            // Estado inicial
            if (!ctrl.verificado)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Selecione arquivos para verificar\nas extensões',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                    ),
                  ],
                ),
              ),

            // Resultados
            if (ctrl.verificado) ...[
              _buildResumo(),
              const SizedBox(height: 16),
              Expanded(child: _buildLista()),
            ],

          ],
        ),
      ),
    );
  }

  // Cards de resumo
  Widget _buildResumo() {
    return Row(
      children: [
        _buildCardResumo(
          'Total',
          ctrl.totalArquivos.toString(),
          Colors.blue,
          Icons.folder,
        ),
        const SizedBox(width: 8),
        _buildCardResumo(
          'Seguros',
          ctrl.totalSeguros.toString(),
          Colors.green,
          Icons.check_circle_outline,
        ),
        const SizedBox(width: 8),
        _buildCardResumo(
          'Perigosos',
          ctrl.totalPerigosos.toString(),
          Colors.red,
          Icons.warning_amber,
        ),
      ],
    );
  }

  Widget _buildCardResumo(String label, String valor, Color cor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 28),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            Text(label, style: TextStyle(color: cor, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Lista de arquivos verificados
  Widget _buildLista() {
    return ListView.builder(
      itemCount: ctrl.resultados.length,
      itemBuilder: (context, index) {
        final item = ctrl.resultados[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: item.perigosa ? Colors.red.shade50 : Colors.green.shade50,
          child: ListTile(
            leading: Icon(
              item.perigosa ? Icons.warning_amber : Icons.check_circle_outline,
              color: item.perigosa ? Colors.red : Colors.green,
            ),
            title: Text(
              item.nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(item.descricao),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.perigosa ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.extensao,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
