import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/cofre_service.dart';

/// RF003/RF004/RF005 — Controller do Cofre usando Firestore
class CofreController extends ChangeNotifier {
  final _service = CofreService();

  // ── Campos do formulário ──────────────────────────────────────────────────

  final txtSite = TextEditingController();
  final txtUsuario = TextEditingController();
  final txtSenha = TextEditingController();
  final txtAnotacao = TextEditingController();

  bool carregando = false;
  String? erro;

  // ── RF005: Stream em tempo real ───────────────────────────────────────────

  Stream<QuerySnapshot> get stream => _service.stream();

  // ── Visibilidade das senhas por docId ─────────────────────────────────────

  final Map<String, bool> _senhasVisiveis = {};
  bool senhaVisivel(String docId) => _senhasVisiveis[docId] ?? false;
  void toggleSenha(String docId) {
    _senhasVisiveis[docId] = !(_senhasVisiveis[docId] ?? false);
    notifyListeners();
  }

  String getSenha(String senhaCodificada) =>
      _service.descriptografar(senhaCodificada);

  // ── RF003: Inserção ───────────────────────────────────────────────────────

  Future<bool> adicionar() async {
    if (txtSite.text.isEmpty || txtSenha.text.isEmpty) {
      erro = 'Site e senha são obrigatórios';
      notifyListeners();
      return false;
    }

    carregando = true;
    erro = null;
    notifyListeners();

    try {
      await _service.adicionar(
        site: txtSite.text.trim(),
        usuario: txtUsuario.text.trim(),
        senha: txtSenha.text,
        anotacao: txtAnotacao.text.trim(),
      );
      limparCampos();
      return true;
    } catch (e) {
      erro = 'Erro ao salvar: $e';
      return false;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // ── RF004: Atualização ────────────────────────────────────────────────────

  Future<bool> atualizar(String docId) async {
    if (txtSite.text.isEmpty || txtSenha.text.isEmpty) {
      erro = 'Site e senha são obrigatórios';
      notifyListeners();
      return false;
    }

    carregando = true;
    erro = null;
    notifyListeners();

    try {
      await _service.atualizar(
        docId: docId,
        site: txtSite.text.trim(),
        usuario: txtUsuario.text.trim(),
        senha: txtSenha.text,
        anotacao: txtAnotacao.text.trim(),
      );
      limparCampos();
      return true;
    } catch (e) {
      erro = 'Erro ao atualizar: $e';
      return false;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // ── Remoção ───────────────────────────────────────────────────────────────

  Future<void> remover(String docId) async {
    await _service.remover(docId);
  }

  // ── Util ──────────────────────────────────────────────────────────────────

  void preencherParaEdicao(Map<String, dynamic> data) {
    txtSite.text = data['site'] ?? '';
    txtUsuario.text = data['usuario'] ?? '';
    txtSenha.text = _service.descriptografar(data['senha'] ?? '');
    txtAnotacao.text = data['anotacao'] ?? '';
  }

  void limparCampos() {
    txtSite.clear();
    txtUsuario.clear();
    txtSenha.clear();
    txtAnotacao.clear();
    erro = null;
  }
}