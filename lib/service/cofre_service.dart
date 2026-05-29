import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// RF003/RF004/RF005 — Coleção "cofre_senhas" no Firestore
/// Estrutura de cada documento (≥5 campos exigidos pelo RF003):
///   uid, site, usuario, senha (base64), anotacao, dataCriacao
class CofreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _colecao {
    final uid = _auth.currentUser!.uid;
    return _db.collection('cofre_senhas');
  }

  // ── Codificação ───────────────────────────────────────────────────────────

  String criptografar(String texto) => base64Encode(utf8.encode(texto));
  String descriptografar(String codificado) =>
      utf8.decode(base64Decode(codificado));

  // ── RF005: Stream em tempo real (StreamBuilder) ───────────────────────────

  Stream<QuerySnapshot> stream() {
    final uid = _auth.currentUser!.uid;
    return _colecao
        .where('uid', isEqualTo: uid)
        .orderBy('dataCriacao', descending: true)
        .snapshots();
  }

  // ── RF003: Inserção ───────────────────────────────────────────────────────

  Future<void> adicionar({
    required String site,
    required String usuario,
    required String senha,
    String anotacao = '',
  }) async {
    final uid = _auth.currentUser!.uid;
    await _colecao.add({
      'uid': uid,
      'site': site,
      'usuario': usuario,
      'senha': criptografar(senha),
      'anotacao': anotacao,
      'dataCriacao': FieldValue.serverTimestamp(),
    });
  }

  // ── RF004: Atualização ────────────────────────────────────────────────────

  Future<void> atualizar({
    required String docId,
    required String site,
    required String usuario,
    required String senha,
    String anotacao = '',
  }) async {
    await _colecao.doc(docId).update({
      'site': site,
      'usuario': usuario,
      'senha': criptografar(senha),
      'anotacao': anotacao,
      'dataAtualizacao': FieldValue.serverTimestamp(),
    });
  }

  // ── Remoção ───────────────────────────────────────────────────────────────

  Future<void> remover(String docId) async {
    await _colecao.doc(docId).delete();
  }
}