import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExtensaoService {
  static const _baseUrl = 'http://127.0.0.1:8080';
  static const _prefKey = 'extensao_historico';

  Future<List<ResultadoExtensao>?> selecionarEVerificar() async {
    final resultado = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (resultado == null) return null;

    final nomes = resultado.files.map((f) => f.name).toList();

    // Chama o Rust
    final response = await http.post(
      Uri.parse('$_baseUrl/extensao/verificar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'arquivos': nomes}),
    );

    final data = jsonDecode(response.body);
    final lista = data['resultados'] as List;
    return lista.map((e) => ResultadoExtensao(
      nome: e['nome'],
      extensao: e['extensao'],
      perigosa: e['perigosa'],
      descricao: e['descricao'],
    )).toList();
  }

  Future<void> salvar(List<ResultadoExtensao> resultados) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = resultados.map((r) => r.toJson()).toList();
    await prefs.setString(_prefKey, jsonEncode(lista));
  }

  Future<List<ResultadoExtensao>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];
    final lista = jsonDecode(raw) as List;
    return lista.map((e) => ResultadoExtensao.fromJson(e)).toList();
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}

class ResultadoExtensao {
  final String nome;
  final String extensao;
  final bool perigosa;
  final String descricao;

  ResultadoExtensao({
    required this.nome,
    required this.extensao,
    required this.perigosa,
    required this.descricao,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'extensao': extensao,
    'perigosa': perigosa,
    'descricao': descricao,
  };

  factory ResultadoExtensao.fromJson(Map<String, dynamic> json) {
    return ResultadoExtensao(
      nome: json['nome'],
      extensao: json['extensao'],
      perigosa: json['perigosa'],
      descricao: json['descricao'],
    );
  }
}