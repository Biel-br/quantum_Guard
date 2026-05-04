import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class YaraService {
  static const _baseUrl = 'http://127.0.0.1:8080';

  Future<Map<String, dynamic>?> selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(withData: true);
    if (resultado == null) return null;
    final arquivo = resultado.files.single;
    return {'nome': arquivo.name, 'bytes': arquivo.bytes!};
  }

  Future<Map<String, dynamic>> escanear(String nome, Uint8List bytes) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/yara/scan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'bytes': bytes.toList(),
      }),
    );
    return jsonDecode(response.body);
  }
}