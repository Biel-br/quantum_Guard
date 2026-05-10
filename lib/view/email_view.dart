import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/email_controller.dart';

class EmailView extends StatefulWidget {
  const EmailView({Key? key}) : super(key: key);

  @override
  State<EmailView> createState() => _EmailViewState();
}

class _EmailViewState extends State<EmailView> {
  final EmailController _controller = GetIt.I<EmailController>();

  @override
  void initState() {
    super.initState();
    _carregarPainel();
  }

  Future<void> _carregarPainel() async {
    await _controller.carregarDashboard();
    setState(() {}); 
  }

  // Pop-up detalhando o que foi bloqueado
  void _mostrarDetalhesBloqueio(BuildContext context, dynamic ameaca) {
    final String textoHumano = ameaca['explicacao_humana'] ?? "E-mail bloqueado por medidas de segurança.";
    final List regras = ameaca['ameacas_yara'] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield, color: Colors.green, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Ameaça Neutralizada",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              
              Text("Remetente: ${ameaca['remetente']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Assunto: ${ameaca['assunto']}", style: const TextStyle(color: Colors.grey)),
              Text("Data do Bloqueio: ${ameaca['data_bloqueio']}", style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // RELATÓRIO DO ASSISTENTE
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.green.shade800),
                        const SizedBox(width: 8),
                        Text(
                          "Relatório do Quantum Guard:", 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800)
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      textoHumano,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),

              if (regras.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("🚨 Motores YARA acionados:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ...regras.map((r) => Text("- ${r['regra_acionada']} (${r['arquivo']})", style: const TextStyle(fontSize: 13))).toList(),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fechar Relatório", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard de Segurança"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarPainel,
          )
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // DESTAQUE: Contador de Ameaças Neutralizadas
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade900, Colors.indigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        "${_controller.totalBloqueado}",
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const Text(
                        "Ameaças Neutralizadas Automaticamente",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // LISTA DE HISTÓRICO
                Expanded(
                  child: _controller.historicoAmeacas.isEmpty
                      ? const Center(
                          child: Text("Sua caixa de entrada está limpa e segura!", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _controller.historicoAmeacas.length,
                          itemBuilder: (context, index) {
                            final ameaca = _controller.historicoAmeacas[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.red.shade100,
                                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                                ),
                                title: Text(
                                  ameaca['remetente'] ?? 'Desconhecido',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ameaca['assunto'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(ameaca['data_bloqueio'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onPressed: () => _mostrarDetalhesBloqueio(context, ameaca),
                                ),
                                onTap: () => _mostrarDetalhesBloqueio(context, ameaca),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}