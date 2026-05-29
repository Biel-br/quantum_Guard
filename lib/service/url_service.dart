import 'package:cloud_functions/cloud_functions.dart';

// Instância apontando para us-central1 (obrigatório para funções v2)
final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

class UrlService {
  Future<ResultadoUrl> verificar(String url) async {
    try {
      final callable = _functions.httpsCallable('url_verificar');
      final result = await callable.call({'url': url});
      final data = result.data;
      return ResultadoUrl(
        url: data['url'],
        dominio: data['dominio'],
        ameaca: data['ameaca'],
        tipoAmeaca: data['tipo_ameaca'],
      );
    } catch (e) {
      throw Exception('Falha ao acionar a Cloud Function: $e');
    }
  }
}

class ResultadoUrl {
  final String url;
  final String dominio;
  final bool ameaca;
  final String? tipoAmeaca;

  ResultadoUrl({
    required this.url,
    required this.dominio,
    required this.ameaca,
    this.tipoAmeaca,
  });
}