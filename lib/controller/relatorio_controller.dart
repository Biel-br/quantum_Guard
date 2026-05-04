import 'package:flutter/material.dart';
import '../service/relatorio_service.dart';

class RelatorioController extends ChangeNotifier {
  final _service = RelatorioService();

  List<EntradaRelatorio> entradas = [];
  bool carregando = false;

  // Totais para o resumo
  int get totalScans => entradas.length;
  int get totalAmeacas => entradas.where((e) => e.ameaca).length;
  int get totalSeguros => entradas.where((e) => !e.ameaca).length;

  // Filtragem
  String filtroAtual = 'Todos';
  final filtros = ['Todos', 'Ameaças', 'Seguros', 'Hash Scanner', 'Verificador de URL', 'Verificador de Extensões'];

  List<EntradaRelatorio> get entradasFiltradas {
    switch (filtroAtual) {
      case 'Ameaças':
        return entradas.where((e) => e.ameaca).toList();
      case 'Seguros':
        return entradas.where((e) => !e.ameaca).toList();
      case 'Todos':
        return entradas;
      default:
        return entradas.where((e) => e.tipo == filtroAtual).toList();
    }
  }

  // Carrega o histórico
  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    entradas = await _service.carregar();
    // Mais recentes primeiro
    entradas.sort((a, b) => b.data.compareTo(a.data));

    carregando = false;
    notifyListeners();
  }

  // Adiciona uma entrada — chamado pelos outros controllers
  Future<void> adicionarEntrada({
    required String tipo,
    required String alvo,
    required String resultado,
    required bool ameaca,
  }) async {
    entradas.insert(0,
      EntradaRelatorio(
        tipo: tipo,
        alvo: alvo,
        resultado: resultado,
        ameaca: ameaca,
        data: DateTime.now(),
      ),
    );

    await _service.salvar(entradas);
    notifyListeners();
  }

  // Limpa todo o histórico
  Future<void> limpar() async {
    entradas = [];
    await _service.limpar();
    notifyListeners();
  }

  // Altera o filtro
  void alterarFiltro(String filtro) {
    filtroAtual = filtro;
    notifyListeners();
  }
}