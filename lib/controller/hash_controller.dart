import 'package:flutter/material.dart';
import '../service/hash_service.dart';
import '../controller/relatorio_controller.dart';
import 'package:get_it/get_it.dart';

class HashController extends ChangeNotifier {
  final _service = HashService();
  final _relatorio = GetIt.I.get<RelatorioController>();

  bool carregando = false;
  String nomeArquivo = '';
  String hash = '';
  String status = '';
  bool ameaca = false;
  bool escaneado = false;

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

      // Agora chama o Rust via scanArquivo
      final resultado = await _service.scanArquivo(
        arquivo['nome'],
        arquivo['bytes'],
      );

      hash = resultado['hash'];
      ameaca = resultado['ameaca'];
      status = resultado['status'];
      escaneado = true;

      _relatorio.adicionarEntrada(
        tipo: 'Hash Scanner',
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
    hash = '';
    status = '';
    ameaca = false;
    escaneado = false;
    notifyListeners();
  }
}