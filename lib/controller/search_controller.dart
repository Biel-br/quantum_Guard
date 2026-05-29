import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchController extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _historicoCompleto = [];
  List<Map<String, dynamic>> resultadosVisiveis = [];

  bool carregando = false;
  String criterioOrdenacao = 'data_desc'; // 'data_desc' ou 'nome_asc'
  String termoAtual = '';

  Future<void> buscarDados() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    carregando = true;
    notifyListeners();

    try {
      // Traz todos os hashes do usuário logado
      final snapshot = await _db
          .collection('hashes_verificados')
          .where('uid', isEqualTo: uid)
          .get();

      _historicoCompleto = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id; // Salva o ID do documento
        return data;
      }).toList();

      aplicarFiltrosEOrdenacao();
    } catch (e) {
      debugPrint("Erro ao buscar histórico: $e");
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void atualizarTermo(String termo) {
    termoAtual = termo.trim().toLowerCase();
    aplicarFiltrosEOrdenacao();
  }

  void mudarOrdenacao(String criterio) {
    criterioOrdenacao = criterio;
    aplicarFiltrosEOrdenacao();
  }

  void aplicarFiltrosEOrdenacao() {
    // 1. Filtrar ignorando maiúsculas e minúsculas (Requisito RF006)
    if (termoAtual.isEmpty) {
      resultadosVisiveis = List.from(_historicoCompleto);
    } else {
      resultadosVisiveis = _historicoCompleto.where((item) {
        final nome = (item['nomeArquivo'] ?? '').toString().toLowerCase();
        return nome.contains(termoAtual);
      }).toList();
    }

    // 2. Ordenar os resultados (Requisito RF006)
    if (criterioOrdenacao == 'nome_asc') {
      resultadosVisiveis.sort((a, b) {
        final nomeA = (a['nomeArquivo'] ?? '').toString().toLowerCase();
        final nomeB = (b['nomeArquivo'] ?? '').toString().toLowerCase();
        return nomeA.compareTo(nomeB);
      });
    } else if (criterioOrdenacao == 'data_desc') {
      resultadosVisiveis.sort((a, b) {
        final dataA = a['data'] ?? '';
        final dataB = b['data'] ?? '';
        return dataB.compareTo(dataA); // Decrescente (mais novo primeiro)
      });
    }

    notifyListeners();
  }

  // Atualiza um campo em uma segunda coleção (RF004)
  Future<void> alternarRevisao(String docId, bool estadoAtual) async {
    try {
      await _db.collection('hashes_verificados').doc(docId).update({
        'revisado': !estadoAtual, // inverte o booleano
      });

      // Atualiza a lista localmente para a tela piscar instantaneamente
      final index = _historicoCompleto.indexWhere((doc) => doc['id'] == docId);
      if (index != -1) {
        _historicoCompleto[index]['revisado'] = !estadoAtual;
        aplicarFiltrosEOrdenacao();
      }
    } catch (e) {
      debugPrint("Erro ao atualizar revisão: $e");
    }
  }
}
