import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../service/url_service.dart';
import '../controller/relatorio_controller.dart';

class UrlController extends ChangeNotifier {
  final _service = UrlService();
  final _relatorio = GetIt.I.get<RelatorioController>();

  final txtUrl = TextEditingController();

  bool carregando = false;
  bool verificado = false;
  ResultadoUrl? resultado;

  Future<void> verificar() async {
    if (txtUrl.text.isEmpty) return;

    carregando = true;
    verificado = false;
    notifyListeners();

    try {
      resultado = await _service.verificar(txtUrl.text);
      verificado = true;

      // Salva no relatório
      _relatorio.adicionarEntrada(
        tipo: 'Verificador de URL',
        alvo: txtUrl.text,
        resultado: resultado!.ameaca
          ? resultado!.tipoAmeaca!
          : 'URL segura',
        ameaca: resultado!.ameaca,
      );

    } catch (e) {
      resultado = null;
    }

    carregando = false;
    notifyListeners();
  }

  void limpar() {
    txtUrl.clear();
    resultado = null;
    verificado = false;
    notifyListeners();
  }
}