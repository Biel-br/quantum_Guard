import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RelatorioService {
  static const _prefKey = 'relatorio_historico';

  // Salva a lista de entradas
  Future<void> salvar(List<EntradaRelatorio> entradas) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = entradas.map((e) => e.toJson()).toList();
    await prefs.setString(_prefKey, jsonEncode(lista));
  }

  // Carrega a lista de entradas
  Future<List<EntradaRelatorio>> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null) return [];

    final lista = jsonDecode(raw) as List;
    return lista.map((e) => EntradaRelatorio.fromJson(e)).toList();
  }

  // Limpa todo o histórico
  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}

// Modelo de cada entrada do relatório
class EntradaRelatorio {
  final String tipo;
  final String alvo;
  final String resultado;
  final bool ameaca;
  final DateTime data;

  EntradaRelatorio({
    required this.tipo,
    required this.alvo,
    required this.resultado,
    required this.ameaca,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'alvo': alvo,
    'resultado': resultado,
    'ameaca': ameaca,
    'data': data.toIso8601String(),
  };

  factory EntradaRelatorio.fromJson(Map<String, dynamic> json) {
    return EntradaRelatorio(
      tipo: json['tipo'],
      alvo: json['alvo'],
      resultado: json['resultado'],
      ameaca: json['ameaca'],
      data: DateTime.parse(json['data']),
    );
  }
}