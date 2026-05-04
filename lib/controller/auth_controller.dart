import 'package:flutter/material.dart';
import '../service/auth_service.dart';

class AuthController extends ChangeNotifier {
  final _service = AuthService();

  final txtEmail = TextEditingController();
  final txtSenha = TextEditingController();

  bool carregando = false;
  bool senhaVisivel = false;
  String? erro;

  void toggleSenha() {
    senhaVisivel = !senhaVisivel;
    notifyListeners();
  }

  Future<bool> login() async {
    erro = null;
    carregando = true;
    notifyListeners();

    erro = await _service.login(txtEmail.text, txtSenha.text);

    carregando = false;
    notifyListeners();
    return erro == null;
  }

  Future<bool> estaLogado() => _service.estaLogado();

  Future<void> logout() async {
    await _service.logout();
    txtEmail.clear();
    txtSenha.clear();
    notifyListeners();
  }

  void limparErro() {
    erro = null;
    notifyListeners();
  }

  // Adicione os controllers de texto
final txtNome = TextEditingController();
final txtTelefone = TextEditingController();
final txtConfirmacaoSenha = TextEditingController();
bool confirmacaoSenhaVisivel = false;

void toggleConfirmacaoSenha() {
  confirmacaoSenhaVisivel = !confirmacaoSenhaVisivel;
  notifyListeners();
}

// Método de cadastro
Future<bool> cadastrar() async {
  erro = null;
  carregando = true;
  notifyListeners();

  erro = await _service.cadastrar(
    nome: txtNome.text,
    email: txtEmail.text,
    telefone: txtTelefone.text,
    senha: txtSenha.text,
    confirmacaoSenha: txtConfirmacaoSenha.text,
  );

  carregando = false;
  notifyListeners();
  return erro == null;
}

void limparCamposCadastro() {
  txtNome.clear();
  txtEmail.clear();
  txtTelefone.clear();
  txtSenha.clear();
  txtConfirmacaoSenha.clear();
  erro = null;
  notifyListeners();
}

final txtEmailRecuperacao = TextEditingController();
bool recuperacaoEnviada = false;

Future<bool> recuperarSenha() async {
  erro = null;
  carregando = true;
  recuperacaoEnviada = false;
  notifyListeners();

  erro = await _service.recuperarSenha(txtEmailRecuperacao.text);
  if (erro == null) recuperacaoEnviada = true;

  carregando = false;
  notifyListeners();
  return erro == null;
}

void limparRecuperacao() {
  txtEmailRecuperacao.clear();
  recuperacaoEnviada = false;
  erro = null;
  notifyListeners();
}

}