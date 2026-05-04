import 'dart:convert';
import 'package:http/http.dart' as http;

class MonitorService {
  static const _baseUrl = 'http://127.0.0.1:8080';

  Future<Map<String, dynamic>> buscarInfo() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/monitor/info'),
    );
    return jsonDecode(response.body);
  }
}