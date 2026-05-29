import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/relatorio_controller.dart';

class RelatorioView extends StatefulWidget {
  const RelatorioView({Key? key}) : super(key: key);

  @override
  State<RelatorioView> createState() => _RelatorioViewState();
}

class _RelatorioViewState extends State<RelatorioView> {
  // Instanciando o controller que você me enviou
  final RelatorioController _controller = RelatorioController();

  @override
  void initState() {
    super.initState();
    // Faz a tela reconstruir quando o filtro mudar
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Relatório de Scans'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar Histórico',
            onPressed: () async {
              // Dialog de confirmação
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Limpar Relatório?'),
                  content: const Text('Todos os registros serão apagados permanentemente.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true), 
                      child: const Text('Limpar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirmar == true) {
                await _controller.limpar();
              }
            },
          )
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Usuário não logado.', style: TextStyle(fontSize: 18)))
          : Column(
              children: [
                // 1. BARRA DE FILTROS (Chips)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: _controller.filtros.map((filtro) {
                        final isSelected = _controller.filtroAtual == filtro;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filtro),
                            selected: isSelected,
                            selectedColor: Colors.blue.shade100,
                            onSelected: (bool selected) {
                              if (selected) {
                                _controller.alterarFiltro(filtro);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // 2. LISTA DE RESULTADOS
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hashes_verificados')
                        .where('uid', isEqualTo: uid)
                        .orderBy('data', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState('Nenhum scan realizado ainda.');
                      }

                      // Aplica o filtro local do Controller
                      final docsFiltrados = _controller.filtrar(snapshot.data!.docs);

                      if (docsFiltrados.isEmpty) {
                        return _buildEmptyState('Nenhum resultado para este filtro.');
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: docsFiltrados.length,
                        itemBuilder: (context, index) {
                          final doc = docsFiltrados[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final bool isAmeaca = data['ameaca'] ?? false;
                          
                          // Tratamento visual de datas e origem
                          final String rawDate = data['data']?.toString() ?? '';
                          final String dataFormatada = rawDate.length > 10 ? rawDate.substring(0, 10) : rawDate;
                          // Lê a 'origem', se não existir, tenta ler o 'tipo' (que você salvava antigamente), senão usa fallback
                          final String origem = data['origem'] ?? data['tipo'] ?? 'Desconhecido';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isAmeaca ? Colors.red.shade200 : Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isAmeaca ? Colors.red.shade100 : Colors.green.shade100,
                                  child: Icon(
                                    isAmeaca ? Icons.gpp_bad : Icons.gpp_good,
                                    color: isAmeaca ? Colors.red.shade700 : Colors.green.shade700,
                                  ),
                                ),
                                title: Text(
                                  data['nomeArquivo'] ?? data['alvo'] ?? 'Arquivo Desconhecido',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      data['status'] ?? data['resultado'] ?? (isAmeaca ? 'Ameaça Detectada' : 'Arquivo Limpo'),
                                      style: TextStyle(
                                        color: isAmeaca ? Colors.red.shade700 : Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        origem,
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(height: 4),
                                    Text(
                                      dataFormatada,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(String mensagem) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            mensagem,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}