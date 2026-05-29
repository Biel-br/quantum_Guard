import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/url_service.dart';

class UrlController extends ChangeNotifier {
  final _service = UrlService();
  final txtUrl = TextEditingController();

  bool carregando = false;
  bool verificado = false;
  ResultadoUrl? resultado;

  Future<void> verificar() async {
    if (txtUrl.text.isEmpty) return;

    carregando = true;
    verificado = false;
    notifyListeners();

    try {
      resultado = await _service.verificar(txtUrl.text);
      verificado = true;

      // ── Gravação Direta no Banco Unificado ─────────────────────────
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('hashes_verificados').add({
          'uid': uid,
          // Usamos 'nomeArquivo' para a URL aparecer corretamente na barra de Pesquisa Avançada
          'nomeArquivo': txtUrl.text, 
          'status': resultado!.ameaca ? (resultado!.tipoAmeaca ?? 'Perigoso') : 'URL Segura',
          'ameaca': resultado!.ameaca,
          'data': DateTime.now().toIso8601String(),
          'origem': 'Verificador de URL', // Fundamental para o Filtro do Relatório funcionar
        });
      }

    } catch (e) {
      resultado = null;
      print("Erro ao verificar URL: $e");
    }

    carregando = false;
    notifyListeners();
  }

  void limpar() {
    txtUrl.clear();
    resultado = null;
    verificado = false;
    notifyListeners();
  }
}