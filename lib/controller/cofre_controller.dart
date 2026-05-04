import 'package:flutter/material.dart';
import '../service/cofre_service.dart';

class CofreController extends ChangeNotifier {
  final _service = CofreService();

  List<Map<String, String>> entradas = [];
  bool carregando = false;

  final txtSite = TextEditingController();
  final txtUsuario = TextEditingController();
  final txtSenha = TextEditingController();

  // Visibilidade das senhas por index
  final Map<int, bool> _senhasVisiveis = {};

  bool senhaVisivel(int index) => _senhasVisiveis[index] ?? false;

  void toggleSenha(int index) {
    _senhasVisiveis[index] = !(_senhasVisiveis[index] ?? false);
    notifyListeners();
  }

  // Carrega as entradas ao iniciar
  Future<void> carregar() async {
    carregando = true;
    notifyListeners();

    entradas = await _service.carregar();

    carregando = false;
    notifyListeners();
  }

  // Adiciona nova entrada
  Future<void> adicionar() async {
    if (txtSite.text.isEmpty || txtSenha.text.isEmpty) return;

    entradas.add({
      'site': txtSite.text,
      'usuario': txtUsuario.text,
      'senha': _service.criptografar(txtSenha.text),
    });

    await _service.salvar(entradas);
    limparCampos();
    notifyListeners();
  }

  // Remove uma entrada
  Future<void> remover(int index) async {
    entradas.removeAt(index);
    _senhasVisiveis.remove(index);
    await _service.salvar(entradas);
    notifyListeners();
  }

  // Retorna a senha descriptografada
  String getSenha(int index) {
    return _service.descriptografar(entradas[index]['senha']!);
  }

  void limparCampos() {
    txtSite.clear();
    txtUsuario.clear();
    txtSenha.clear();
  }
}