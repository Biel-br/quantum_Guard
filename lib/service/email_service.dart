import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // Lembre-se de usar o IP correto (127.0.0.1 para Web/Linux)
  final String baseUrl = "http://127.0.0.1:8000/api/v1";

  Future<Map<String, dynamic>> obterHistoricoDashboard() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/historico'));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception("Falha ao carregar o painel de segurança.");
      }
    } catch (e) {
      print("Erro no Service: $e");
      return {"ameacas_bloqueadas": [], "total": 0};
    }
  }
}