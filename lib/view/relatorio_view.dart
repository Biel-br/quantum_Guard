import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/relatorio_controller.dart';
import '../service/relatorio_service.dart';

class RelatorioView extends StatefulWidget {
  const RelatorioView({super.key});

  @override
  State<RelatorioView> createState() => _RelatorioViewState();
}

class _RelatorioViewState extends State<RelatorioView> {
  final ctrl = GetIt.I.get<RelatorioController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
    ctrl.carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Segurança', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (ctrl.entradas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Limpar histórico',
              onPressed: () => _confirmarLimpar(context),
            ),
        ],
      ),
      body: ctrl.carregando
        ? const Center(child: CircularProgressIndicator())
        : ctrl.entradas.isEmpty
          ? _buildVazio()
          : Column(
              children: [
                _buildResumo(),
                _buildFiltros(),
                Expanded(child: _buildLista()),
              ],
            ),
    );
  }

  // Tela vazia
  Widget _buildVazio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum scan realizado ainda',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Use as funcionalidades do app\npara gerar o relatório',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Cards de resumo
  Widget _buildResumo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade700,
      child: Row(
        children: [
          _buildCardResumo('Total', ctrl.totalScans, Colors.white, Icons.list),
          _buildCardResumo('Ameaças', ctrl.totalAmeacas, Colors.red.shade200, Icons.warning_amber),
          _buildCardResumo('Seguros', ctrl.totalSeguros, Colors.green.shade300, Icons.shield),
        ],
      ),
    );
  }

  Widget _buildCardResumo(String label, int valor, Color cor, IconData icone) {
    return Expanded(
      child: Column(
        children: [
          Icon(icone, color: cor, size: 28),
          const SizedBox(height: 4),
          Text(
            valor.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          Text(label, style: TextStyle(color: cor, fontSize: 12)),
        ],
      ),
    );
  }

  // Barra de filtros
  Widget _buildFiltros() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ctrl.filtros.length,
        itemBuilder: (context, index) {
          final filtro = ctrl.filtros[index];
          final selecionado = ctrl.filtroAtual == filtro;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ctrl.alterarFiltro(filtro),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: selecionado ? Colors.red.shade700 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filtro,
                  style: TextStyle(
                    color: selecionado ? Colors.white : Colors.black87,
                    fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Lista de entradas
  Widget _buildLista() {
    final lista = ctrl.entradasFiltradas;

    if (lista.isEmpty) {
      return Center(
        child: Text(
          'Nenhum resultado para "${ctrl.filtroAtual}"',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final entrada = lista[index];
        return _buildEntrada(entrada);
      },
    );
  }

  // Card de cada entrada
  Widget _buildEntrada(EntradaRelatorio entrada) {
    final cor = entrada.ameaca ? Colors.red : Colors.green;
    final icone = _iconePorTipo(entrada.tipo);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.1),
          child: Icon(icone, color: cor, size: 20),
        ),
        title: Text(
          entrada.alvo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entrada.resultado, style: TextStyle(color: cor, fontSize: 13)),
            Text(
              '${entrada.tipo} • ${_formatarData(entrada.data)}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        trailing: Icon(
          entrada.ameaca ? Icons.warning_amber : Icons.check_circle_outline,
          color: cor,
        ),
        isThreeLine: true,
      ),
    );
  }

  // Ícone por tipo de scan
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

  // Formata a data
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
           '${data.month.toString().padLeft(2, '0')}/'
           '${data.year} '
           '${data.hour.toString().padLeft(2, '0')}:'
           '${data.minute.toString().padLeft(2, '0')}';
  }

  // Dialog confirmar limpeza
  void _confirmarLimpar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content: const Text('Todos os registros serão apagados permanentemente.'),
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
            onPressed: () {
              ctrl.limpar();
              Navigator.pop(context);
            },
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}
