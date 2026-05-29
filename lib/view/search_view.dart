import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _buscaEC = TextEditingController();
  String termoBusca = '';
  String criterioOrdenacao = 'data_desc'; // Padrão: mais recentes primeiro

  @override
  void dispose() {
    _buscaEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pesquisar Histórico', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. BARRA DE PESQUISA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaEC,
              onChanged: (val) {
                // Atualiza a tela a cada letra digitada
                setState(() {
                  termoBusca = val.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nome do arquivo...',
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade800),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // 2. FILTROS DE ORDENAÇÃO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Ordenar por: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Mais Recentes'),
                  selected: criterioOrdenacao == 'data_desc',
                  selectedColor: Colors.blue.shade100,
                  onSelected: (val) {
                    setState(() => criterioOrdenacao = 'data_desc');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('A-Z'),
                  selected: criterioOrdenacao == 'nome_asc',
                  selectedColor: Colors.blue.shade100,
                  onSelected: (val) {
                    setState(() => criterioOrdenacao = 'nome_asc');
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // 3. LISTA REATIVA COM STREAMBUILDER
          Expanded(
            child: uid == null
                ? const Center(child: Text("Usuário não autenticado"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('hashes_verificados')
                        .where('uid', isEqualTo: uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erro: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('Nenhum registro no banco.'));
                      }

                      // Mapeia os documentos do Firebase para uma lista manipulável
                      var documentos = snapshot.data!.docs.map((doc) {
                        return doc.data() as Map<String, dynamic>;
                      }).toList();

                      // Aplica o Filtro de Pesquisa (Ignorando maiúsculas)
                      if (termoBusca.isNotEmpty) {
                        documentos = documentos.where((doc) {
                          final nome = (doc['nomeArquivo'] ?? '').toString().toLowerCase();
                          return nome.contains(termoBusca);
                        }).toList();
                      }

                      // Aplica a Ordenação
                      if (criterioOrdenacao == 'data_desc') {
                        documentos.sort((a, b) {
                          final dataA = a['data'] ?? '';
                          final dataB = b['data'] ?? '';
                          return dataB.compareTo(dataA); // Do mais novo para o mais velho
                        });
                      } else if (criterioOrdenacao == 'nome_asc') {
                        documentos.sort((a, b) {
                          final nomeA = (a['nomeArquivo'] ?? '').toString().toLowerCase();
                          final nomeB = (b['nomeArquivo'] ?? '').toString().toLowerCase();
                          return nomeA.compareTo(nomeB); // Alfabético
                        });
                      }

                      // Feedback caso a pesquisa não encontre nada
                      if (documentos.isEmpty) {
                        return const Center(
                          child: Text('Nenhum arquivo corresponde à sua busca.'),
                        );
                      }

                      // Constrói a lista visual
                      return ListView.builder(
                        itemCount: documentos.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final item = documentos[index];
                          final bool ameaca = item['ameaca'] ?? false;
                          
                          final String rawDate = item['data']?.toString() ?? '';
                          final String dataFormatada = rawDate.length > 10 ? rawDate.substring(0, 10) : rawDate;

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: ameaca ? Colors.red.shade200 : Colors.green.shade200,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                ameaca ? Icons.gpp_bad : Icons.gpp_good,
                                color: ameaca ? Colors.red.shade600 : Colors.green.shade600,
                              ),
                              title: Text(
                                item['nomeArquivo'] ?? 'Desconhecido',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                item['status'] ?? '',
                                style: TextStyle(
                                  color: ameaca ? Colors.red.shade700 : Colors.green.shade700,
                                ),
                              ),
                              trailing: Text(dataFormatada, style: const TextStyle(fontSize: 12)),
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
}