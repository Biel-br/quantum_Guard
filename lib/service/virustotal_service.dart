import 'dart:convert';
import 'package:http/http.dart' as http;

class VirusTotalService {
  // Cole a sua chave copiada do site do VirusTotal aqui
  final String _apiKey = '2376383b585c07a8faf501819cef1da48040eb60526a780f199c1290412341af'; 
  final String _baseUrl = 'https://www.virustotal.com/api/v3';

  /// Consulta um Hash SHA-256 na API pública do VirusTotal
  Future<Map<String, dynamic>> consultarHash(String hashStr) async {
    if (_apiKey == '2376383b585c07a8faf501819cef1da48040eb60526a780f199c1290412341af') {
      return {'sucesso': false, 'erro': 'Chave da API não configurada no código.'};
    }

    final url = Uri.parse('$_baseUrl/files/$hashStr');

    try {
      // Fazendo a requisição HTTP (O que o professor quer ver no RF007)
      final response = await http.get(
        url,
        headers: {
          'x-apikey': _apiKey,
        },
      );

      // Status 200 = Sucesso. O arquivo existe no banco deles.
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Navegando no JSON para pegar os status da última análise
        final stats = data['data']['attributes']['last_analysis_stats'];

        return {
          'sucesso': true,
          'maliciosos': stats['malicious'] ?? 0,
          'suspeitos': stats['suspicious'] ?? 0,
          'inofensivos': stats['harmless'] ?? 0,
          'nao_detectados': stats['undetected'] ?? 0,
        };
      } 
      // Status 404 = O arquivo nunca foi visto pelo VirusTotal antes
      else if (response.statusCode == 404) {
        return {'sucesso': false, 'erro': 'Este hash nunca foi analisado pelo VirusTotal.'};
      } 
      else {
        return {'sucesso': false, 'erro': 'Erro na API: ${response.statusCode}'};
      }
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro de conexão: Verifique sua internet.'};
    }
  }
}