import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../service/extensao_service.dart';
import '../controller/relatorio_controller.dart';

class ExtensaoController extends ChangeNotifier {
  final _service = ExtensaoService();
  final _relatorio = GetIt.I.get<RelatorioController>();

  bool carregando = false;
  bool verificado = false;
  List<ResultadoExtensao> resultados = [];

  int get totalArquivos => resultados.length;
  int get totalPerigosos => resultados.where((r) => r.perigosa).length;
  int get totalSeguros => resultados.where((r) => !r.perigosa).length;

  // Carrega histórico ao iniciar
  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    resultados = await _service.carregar();
    if (resultados.isNotEmpty) verificado = true;

    carregando = false;
    notifyListeners();
  }

  Future<void> selecionarEVerificar() async {
    carregando = true;
    notifyListeners();

    try {
      final lista = await _service.selecionarEVerificar();
      if (lista == null) {
        carregando = false;
        notifyListeners();
        return;
      }

      // Adiciona aos resultados existentes
      resultados.addAll(lista);
      verificado = true;

      // Salva no SharedPreferences
      await _service.salvar(resultados);

      // Salva perigosos no relatório
      for (final r in lista.where((r) => r.perigosa)) {
        _relatorio.adicionarEntrada(
          tipo: 'Verificador de Extensões',
          alvo: r.nome,
          resultado: r.descricao,
          ameaca: true,
        );
      }

      if (lista.every((r) => !r.perigosa)) {
        _relatorio.adicionarEntrada(
          tipo: 'Verificador de Extensões',
          alvo: '${lista.length} arquivo(s) verificado(s)',
          resultado: 'Nenhuma extensão perigosa encontrada',
          ameaca: false,
        );
      }

    } catch (e) {
      resultados = [];
    }

    carregando = false;
    notifyListeners();
  }

  Future<void> limpar() async {
    resultados = [];
    verificado = false;
    await _service.limpar();
    notifyListeners();
  }
}