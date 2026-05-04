import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _usuariosKey = 'usuarios';
  static const _usuarioLogadoKey = 'usuario_logado';

  // Valida formato de email
  bool validarEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Carrega lista de usuários
  Future<List<Map<String, dynamic>>> carregarUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usuariosKey);
    if (raw == null) return [];
    final lista = jsonDecode(raw) as List;
    return lista.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Realiza o login
  Future<String?> login(String email, String senha) async {
    if (email.isEmpty || senha.isEmpty) {
      return 'Preencha todos os campos';
    }
    if (!validarEmail(email)) {
      return 'E-mail inválido';
    }

    final usuarios = await carregarUsuarios();
    final usuario = usuarios.firstWhere(
      (u) => u['email'] == email && u['senha'] == senha,
      orElse: () => {},
    );

    if (usuario.isEmpty) {
      return 'E-mail ou senha incorretos';
    }

    // Salva o usuário logado
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usuarioLogadoKey, jsonEncode(usuario));
    return null; // null = sucesso
  }

  // Verifica se já está logado
  Future<bool> estaLogado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usuarioLogadoKey) != null;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usuarioLogadoKey);
  }

  // Cadastra novo usuário
Future<String?> cadastrar({
  required String nome,
  required String email,
  required String telefone,
  required String senha,
  required String confirmacaoSenha,
}) async {
  // Validações
  if (nome.isEmpty || email.isEmpty || telefone.isEmpty ||
      senha.isEmpty || confirmacaoSenha.isEmpty) {
    return 'Preencha todos os campos';
  }
  if (!validarEmail(email)) {
    return 'E-mail inválido';
  }
  if (senha != confirmacaoSenha) {
    return 'As senhas não coincidem';
  }
  if (senha.length < 6) {
    return 'A senha deve ter no mínimo 6 caracteres';
  }

  // Verifica se email já existe
  final usuarios = await carregarUsuarios();
  final existe = usuarios.any((u) => u['email'] == email);
  if (existe) {
    return 'E-mail já cadastrado';
  }

  // Salva o novo usuário
  usuarios.add({
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'senha': senha,
  });

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_usuariosKey, jsonEncode(usuarios));

  // Já loga o usuário após cadastro
  await prefs.setString(_usuarioLogadoKey, jsonEncode(usuarios.last));

  return null; // null = sucesso
}

// Recuperação de senha
Future<String?> recuperarSenha(String email) async {
  if (email.isEmpty) {
    return 'Preencha o campo de e-mail';
  }
  if (!validarEmail(email)) {
    return 'E-mail inválido';
  }

  final usuarios = await carregarUsuarios();
  final existe = usuarios.any((u) => u['email'] == email);

  if (!existe) {
    return 'E-mail não encontrado';
  }

  // Aqui simulamos o envio do email
  return null; // null = sucesso
}

}