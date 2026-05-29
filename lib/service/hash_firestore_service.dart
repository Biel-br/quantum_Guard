import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// RF003 — Coleção "hashes_verificados" no Firestore
/// Estrutura de cada documento (≥5 campos exigidos pelo RF003):
///   uid, nomeArquivo, hash, ameaca, status, data
class HashFirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _colecao => _db.collection('hashes_verificados');

  // ── RF005: Stream em tempo real ───────────────────────────────────────────

  Stream<QuerySnapshot> stream() {
    final uid = _auth.currentUser!.uid;
    return _colecao
        .where('uid', isEqualTo: uid)
        .orderBy('data', descending: true)
        .snapshots();
  }

  // ── RF003: Inserção ───────────────────────────────────────────────────────

  Future<void> salvar({
    required String nomeArquivo,
    required String hash,
    required bool ameaca,
    required String status,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _colecao.add({
      'uid': uid,
      'nomeArquivo': nomeArquivo,
      'hash': hash,
      'ameaca': ameaca,
      'status': status,
      'data': FieldValue.serverTimestamp(),
    });
  }

  // ── RF004: Atualização (marcar revisado) ──────────────────────────────────

  Future<void> marcarRevisado(String docId) async {
    await _colecao.doc(docId).update({'revisado': true});
  }
}