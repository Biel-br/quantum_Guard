import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/relatorio_service.dart';

/// RF006 — Tela exclusiva de pesquisa na coleção "relatorio"
/// - Interface gráfica exclusiva para pesquisa
/// - Case-insensitive
/// - Ordenação por data, tipo ou alvo
class PesquisaRelatorioView extends StatefulWidget {
  const PesquisaRelatorioView({super.key});

  @override
  State<PesquisaRelatorioView> createState() =>
      _PesquisaRelatorioViewState();
}

class _PesquisaRelatorioViewState extends State<PesquisaRelatorioView> {
  final _service = RelatorioService();
  final _txtBusca = TextEditingController();

  List<QueryDocumentSnapshot> _resultados = [];
  bool _buscando = false;

  // Ordenação
  String _ordenarPor = 'data';
  bool _descrescente = true;

  final _opcoesOrdenacao = const {
    'data': 'Data',
    'tipo': 'Tipo',
    'alvo': 'Alvo',
  };

  @override
  void initState() {
    super.initState();
    // Força a busca de todos os dados assim que a tela é aberta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buscar();
    });
  }

  Future<void> _buscar() async {
    final termo = _txtBusca.text.trim();
    setState(() {
      _buscando = true;
    });

    final resultado = await _service.pesquisar(
      termo: termo,
      ordenarPor: _ordenarPor,
      descrescente: _descrescente,
    );

    setState(() {
      _resultados = resultado;
      _buscando = false;
    });
  }

  @override
  void dispose() {
    _txtBusca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Pesquisar Relatório',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Área de busca ───────────────────────────────────────────────
          Container(
            color: Colors.red.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // Campo de busca
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _txtBusca,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _buscar(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por tipo, alvo ou resultado...',
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.grey),
                      suffixIcon: _txtBusca.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.grey),
                              onPressed: () {
                                _txtBusca.clear();
                                // Quando limpa o X, busca tudo de novo
                                _buscar(); 
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    // Pesquisa em tempo real a cada letra digitada
                    onChanged: (_) => _buscar(), 
                  ),
                ),

                const SizedBox(height: 12),

                // Linha de ordenação
                Row(
                  children: [
                    const Text('Ordenar por:',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 8),
                    // Dropdown de critério
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _ordenarPor,
                            dropdownColor: Colors.red.shade800,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            items: _opcoesOrdenacao.entries
                                .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _ordenarPor = v!);
                              _buscar(); // Atualiza a lista ao mudar a ordem
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Toggle asc/desc
                    GestureDetector(
                      onTap: () {
                        setState(() => _descrescente = !_descrescente);
                        _buscar(); // Atualiza a lista ao mudar asc/desc
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _descrescente
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _descrescente ? 'Desc' : 'Asc',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Resultados ──────────────────────────────────────────────────
          Expanded(
            child: _buscando && _resultados.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                    ? _buildSemResultados()
                    : _buildResultados(),
          ),
        ],
      ),
    );
  }

  Widget _buildSemResultados() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _txtBusca.text.isEmpty 
                ? 'Nenhum relatório encontrado no histórico.'
                : 'Nenhum resultado para\n"${_txtBusca.text}"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${_resultados.length} resultado(s) encontrado(s)',
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontStyle: FontStyle.italic),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _resultados.length,
            itemBuilder: (context, index) {
              final doc = _resultados[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildCard(data);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    final ameaca = data['ameaca'] as bool? ?? false;
    final tipo = data['tipo'] as String? ?? '';
    final alvo = data['alvo'] as String? ?? '';
    final resultado = data['resultado'] as String? ?? '';
    final ts = data['data'] as Timestamp?;
    final dataHora = ts?.toDate() ?? DateTime.now();
    final cor = ameaca ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.1),
          child: Icon(_iconePorTipo(tipo), color: cor, size: 20),
        ),
        title: Text(
          alvo,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destaca o termo buscado
            _buildTextoDestacado(resultado, _txtBusca.text, cor),
            const SizedBox(height: 2),
            Text(
              '$tipo • ${_formatarData(dataHora)}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        trailing: Icon(
          ameaca
              ? Icons.warning_amber
              : Icons.check_circle_outline,
          color: cor,
        ),
        isThreeLine: true,
      ),
    );
  }

  /// Destaca o termo pesquisado no texto (case-insensitive)
  Widget _buildTextoDestacado(
      String texto, String termo, Color corBase) {
    if (termo.isEmpty) {
      return Text(texto,
          style: TextStyle(color: corBase, fontSize: 13));
    }

    final lower = texto.toLowerCase();
    final termoLower = termo.toLowerCase();
    final idx = lower.indexOf(termoLower);

    if (idx == -1) {
      return Text(texto,
          style: TextStyle(color: corBase, fontSize: 13));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: corBase, fontSize: 13),
        children: [
          TextSpan(text: texto.substring(0, idx)),
          TextSpan(
            text: texto.substring(idx, idx + termo.length),
            style: const TextStyle(
              backgroundColor: Color(0x44FFEB3B),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: texto.substring(idx + termo.length)),
        ],
      ),
    );
  }

  IconData _iconePorTipo(String tipo) {
    switch (tipo) {
      case 'Hash Scanner':
        return Icons.search;
      case 'Verificador de URL':
        return Icons.link;
      case 'Verificador de Extensões':
        return Icons.folder;
      default:
        return Icons.security;
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }
}