import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/relatorio_service.dart';

class RelatorioController extends ChangeNotifier {
  final _service = RelatorioService();

  // ── Estado ────────────────────────────────────────────────────────────────
  Stream<QuerySnapshot> get stream => _service.stream();

  String filtroAtual = 'Todos';
  final filtros = [
    'Todos',
    'Ameaças',
    'Seguros',
    'Hash Scanner',
    'Verificador de URL',
  ];

  // ── Inserção / Atualização / Limpeza ─────────────────────────────────────
  Future<void> adicionarEntrada({
    required String tipo,
    required String alvo,
    required String resultado,
    required bool ameaca,
  }) async {
    await _service.adicionar(
      tipo: tipo,
      alvo: alvo,
      resultado: resultado,
      ameaca: ameaca,
    );
  }

  Future<void> marcarRevisado(String docId) async {
    await _service.marcarRevisado(docId);
  }

  Future<void> limpar() async {
    await _service.limpar();
  }

  // ── Filtro (CORRIGIDO PARA NÃO DAR TELA VERMELHA) ────────────────────────
  void alterarFiltro(String filtro) {
    filtroAtual = filtro;
    notifyListeners();
  }

  List<QueryDocumentSnapshot> filtrar(List<QueryDocumentSnapshot> docs) {
    if (filtroAtual == 'Todos') return docs;

    return docs.where((d) {
      // Leitura segura do Firebase transformando num Map
      final data = d.data() as Map<String, dynamic>?;
      if (data == null) return false;

      if (filtroAtual == 'Ameaças') {
        return data['ameaca'] == true;
      } else if (filtroAtual == 'Seguros') {
        return data['ameaca'] == false;
      } else {
        // Pega a origem do scan ignorando se salvou como 'origem' ou 'tipo' no passado
        final origem = data['origem'] ?? data['tipo'] ?? 'Desconhecido';
        return origem == filtroAtual;
      }
    }).toList();
  }
}