import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';

final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

class HashService {
  Future<Map<String, dynamic>?> selecionarArquivo() async {
    final resultado = await FilePicker.pickFiles(withData: true);
    if (resultado == null) return null;
    final arquivo = resultado.files.single;
    return {'nome': arquivo.name, 'bytes': arquivo.bytes!};
  }

  Future<Map<String, dynamic>> scanArquivo(String nome, Uint8List bytes) async {
    try {
      final callable = _functions.httpsCallable('hash_scan');
      final result = await callable.call({
        'nome': nome,
        'bytes': bytes.toList(),
      });
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('Falha ao acionar a Cloud Function hash_scan: $e');
    }
  }
}