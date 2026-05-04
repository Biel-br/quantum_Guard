import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../service/yara_service.dart';
import '../controller/relatorio_controller.dart';

class YaraController extends ChangeNotifier {
  final _service = YaraService();
  final _relatorio = GetIt.I.get<RelatorioController>();

  bool carregando = false;
  bool escaneado = false;
  String nomeArquivo = '';
  String status = '';
  bool ameaca = false;
  List<dynamic> matches = [];

  Future<void> selecionarEscanear() async {
    carregando = true;
    escaneado = false;
    notifyListeners();

    try {
      final arquivo = await _service.selecionarArquivo();
      if (arquivo == null) {
        carregando = false;
        notifyListeners();
        return;
      }

      nomeArquivo = arquivo['nome'];
      final resultado = await _service.escanear(
        arquivo['nome'],
        arquivo['bytes'],
      );

      ameaca = resultado['ameaca'];
      status = resultado['status'];
      matches = resultado['matches'] ?? [];
      escaneado = true;

      _relatorio.adicionarEntrada(
        tipo: 'YARA Scanner',
        alvo: nomeArquivo,
        resultado: status,
        ameaca: ameaca,
      );

    } catch (e) {
      status = 'Erro ao conectar com o backend Rust';
    }

    carregando = false;
    notifyListeners();
  }

  void limpar() {
    nomeArquivo = '';
    status = '';
    ameaca = false;
    matches = [];
    escaneado = false;
    notifyListeners();
  }
}