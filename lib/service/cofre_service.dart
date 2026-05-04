import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CofreService {
  static const _prefKey = 'cofre_senhas';

  // Codifica em Base64 
  String criptografar(String texto) {
    return base64Encode(utf8.encode(texto));
  }

  // Decodifica de Base64
  String descriptografar(String textoCodificado) {
    return utf8.decode(base64Decode(textoCodificado));
  }

  // Salva todas as entradas no SharedPreferences
  Future<void> salvar(List<Map<String, String>> entradas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(entradas));
  }

  // Carrega todas as entradas
  Future<List<Map<String, String>>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];

    final lista = jsonDecode(raw) as List;
    return lista.map((e) => Map<String, String>.from(e)).toList();
  }
}