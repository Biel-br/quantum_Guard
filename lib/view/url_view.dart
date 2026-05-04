import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/url_controller.dart';

class UrlView extends StatefulWidget {
  const UrlView({super.key});

  @override
  State<UrlView> createState() => _UrlViewState();
}

class _UrlViewState extends State<UrlView> {
  final ctrl = GetIt.I.get<UrlController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificador de URLs', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Campo de URL
            TextField(
              controller: ctrl.txtUrl,
              decoration: InputDecoration(
                labelText: 'Digite ou cole a URL',
                hintText: 'ex: https://exemplo.com',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: ctrl.txtUrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: ctrl.limpar,
                    )
                  : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => ctrl.verificar(),
            ),

            const SizedBox(height: 16),

            // Botão verificar
            SizedBox(
              width: double.infinity,
              child: ctrl.carregando
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Verificar URL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await ctrl.verificar();
                      if (mounted && ctrl.verificado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ctrl.resultado!.ameaca
                              ? '⚠️ URL Perigosa!'
                              : '✅ URL Segura'),
                            backgroundColor: ctrl.resultado!.ameaca
                              ? Colors.red
                              : Colors.green,
                          ),
                        );
                      }
                    },
                  ),
            ),

            const SizedBox(height: 40),

            // Resultado
            if (ctrl.verificado && ctrl.resultado != null)
              _buildResultado(ctrl.resultado!),

            // Estado inicial
            if (!ctrl.verificado)
              Column(
                children: [
                  Icon(Icons.travel_explore, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Insira uma URL para verificar',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultado(resultado) {
    final ameaca = resultado.ameaca;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ameaca ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ameaca ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        children: [
          // Ícone
          Icon(
            ameaca ? Icons.dangerous : Icons.verified_user,
            size: 64,
            color: ameaca ? Colors.red : Colors.green,
          ),

          const SizedBox(height: 12),

          // Status principal
          Text(
            ameaca ? '⚠️ URL Perigosa!' : '✅ URL Segura',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ameaca ? Colors.red : Colors.green,
            ),
          ),

          const SizedBox(height: 8),

          // Domínio analisado
          Text(
            'Domínio: ${resultado.dominio}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),

          // Tipo de ameaça
          if (ameaca && resultado.tipoAmeaca != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                resultado.tipoAmeaca!,
                style: TextStyle(color: Colors.red.shade800, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
