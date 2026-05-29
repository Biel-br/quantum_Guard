import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// RF003/RF004/RF005 — Coleção "relatorio" no Firestore
/// Estrutura de cada documento (≥5 campos exigidos pelo RF003):
///   uid, tipo, alvo, resultado, ameaca, data
class RelatorioService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _colecao => _db.collection('relatorio');

  // ── RF005: Stream em tempo real ───────────────────────────────────────────

  Stream<QuerySnapshot> stream() {
    final uid = _auth.currentUser!.uid;
    return _colecao
        .where('uid', isEqualTo: uid)
        .orderBy('data', descending: true)
        .snapshots();
  }

  // ── RF003: Inserção ───────────────────────────────────────────────────────

  Future<void> adicionar({
    required String tipo,
    required String alvo,
    required String resultado,
    required bool ameaca,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _colecao.add({
      'uid': uid,
      'tipo': tipo,
      'alvo': alvo,
      'resultado': resultado,
      'ameaca': ameaca,
      'data': FieldValue.serverTimestamp(),
    });
  }

  // ── RF004: Atualização (marcar revisado) ──────────────────────────────────

  Future<void> marcarRevisado(String docId) async {
    await _colecao.doc(docId).update({'revisado': true});
  }

  // ── Limpar histórico do usuário ───────────────────────────────────────────

  Future<void> limpar() async {
    final uid = _auth.currentUser!.uid;
    final docs = await _colecao.where('uid', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── RF006: Pesquisa case-insensitive por tipo/alvo ────────────────────────

  Future<List<QueryDocumentSnapshot>> pesquisar({
    required String termo,
    String ordenarPor = 'data', // 'data' | 'alvo' | 'tipo'
    bool descrescente = true,
  }) async {
    final uid = _auth.currentUser!.uid;
    final termoLower = termo.toLowerCase();

    // Busca todos do usuário e filtra localmente (Firestore não suporta
    // LIKE nativo; para escala maior usaria Algolia/Typesense)
    final snap = await _colecao
        .where('uid', isEqualTo: uid)
        .orderBy(ordenarPor, descending: descrescente)
        .get();

    return snap.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final alvo = (data['alvo'] as String? ?? '').toLowerCase();
      final tipo = (data['tipo'] as String? ?? '').toLowerCase();
      final resultado = (data['resultado'] as String? ?? '').toLowerCase();
      return alvo.contains(termoLower) ||
          tipo.contains(termoLower) ||
          resultado.contains(termoLower);
    }).toList();
  }
}

// ── Modelo local (mantido para compatibilidade com RelatorioController) ───────

class EntradaRelatorio {
  final String? docId;
  final String tipo;
  final String alvo;
  final String resultado;
  final bool ameaca;
  final DateTime data;

  EntradaRelatorio({
    this.docId,
    required this.tipo,
    required this.alvo,
    required this.resultado,
    required this.ameaca,
    required this.data,
  });

  factory EntradaRelatorio.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EntradaRelatorio(
      docId: doc.id,
      tipo: d['tipo'] ?? '',
      alvo: d['alvo'] ?? '',
      resultado: d['resultado'] ?? '',
      ameaca: d['ameaca'] ?? false,
      data: (d['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}