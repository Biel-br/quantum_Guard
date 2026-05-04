import 'dart:convert';
import 'package:http/http.dart' as http;

class UrlService {
  static const _baseUrl = 'http://127.0.0.1:8080';

  Future<ResultadoUrl> verificar(String url) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/url/verificar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url}),
    );
    final data = jsonDecode(response.body);
    return ResultadoUrl(
      url: data['url'],
      dominio: data['dominio'],
      ameaca: data['ameaca'],
      tipoAmeaca: data['tipo_ameaca'],
    );
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