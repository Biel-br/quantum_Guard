import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  
  static const _webClientId =
      '237814584611-51b4gi35djkf2ntbjf7r2i50p8h356du.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static const List<String> _googleScopes = <String>[
    'email',
    'https://www.googleapis.com/auth/gmail.modify',
  ];

  // ── helpers ──────────────────────────────────────────────────────────────

  bool validarEmail(String email) =>
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);

  /// RF002 — senha deve ter ≥8 chars, maiúscula, minúscula e caractere especial
  String? validarSenhaForte(String senha) {
    if (senha.length < 8) return 'A senha deve ter no mínimo 8 caracteres';
    if (!senha.contains(RegExp(r'[A-Z]'))) {
      return 'A senha deve conter pelo menos uma letra maiúscula';
    }
    if (!senha.contains(RegExp(r'[a-z]'))) {
      return 'A senha deve conter pelo menos uma letra minúscula';
    }
    if (!senha.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) {
      return 'A senha deve conter pelo menos um caractere especial';
    }
    return null; // válida
  }

  User? get usuarioAtual => _auth.currentUser;

  // ── RF001: Login e-mail/senha ─────────────────────────────────────────────

  Future<String?> login(String email, String senha) async {
    if (email.isEmpty || senha.isEmpty) return 'Preencha todos os campos';
    if (!validarEmail(email)) return 'E-mail inválido';

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  

  /// Retorna null se sucesso, ou mensagem de erro.
  Future<String?> loginComGoogle() async {
    try {
      await _googleSignIn.initialize(serverClientId: _webClientId);

      // 1. Abre o seletor de conta Google e autentica o usuário
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: _googleScopes,
      );

      // 2. Obtém o ID token para login no Firebase Auth
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        return 'Falha ao obter token do Google';
      }

      // 3. Faz login no Firebase Auth
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCred = await _auth.signInWithCredential(credential);
      final uid = userCred.user!.uid;

      // 4. Salva os dados do usuário na coleção "usuarios" (igual ao cadastro)
      await _db.collection('usuarios').doc(uid).set({
        'nome': userCred.user!.displayName ?? '',
        'email': userCred.user!.email ?? '',
        'telefone': '',
        'dataCadastro': FieldValue.serverTimestamp(),
        'plano': 'gratuito',
      }, SetOptions(merge: true)); // merge: não sobrescreve se já existir

      // 5. Salva os tokens OAuth para a patrulha agendada usar
      final GoogleSignInClientAuthorization authz = await googleUser
          .authorizationClient
          .authorizeScopes(['https://www.googleapis.com/auth/gmail.modify']);
      final GoogleSignInServerAuthorization? serverAuth = await googleUser
          .authorizationClient
          .authorizeServer(['https://www.googleapis.com/auth/gmail.modify']);

      await _db.collection('usuarios_tokens').doc(uid).set(
        {
          'access_token': authz.accessToken,
          'refresh_token': serverAuth?.serverAuthCode ?? '',
          'atualizado_em': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ); // merge: preserva o refresh_token salvo anteriormente

      return null; // sucesso
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    } catch (e) {
      return 'Erro ao fazer login com Google: $e';
    }
  }

  // ── RF001: Recuperação de senha ───────────────────────────────────────────

  Future<String?> recuperarSenha(String email) async {
    if (email.isEmpty) return 'Preencha o campo de e-mail';
    if (!validarEmail(email)) return 'E-mail inválido';

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  // ── RF002: Cadastro ───────────────────────────────────────────────────────

  Future<String?> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String confirmacaoSenha,
  }) async {
    if (nome.isEmpty ||
        email.isEmpty ||
        telefone.isEmpty ||
        senha.isEmpty ||
        confirmacaoSenha.isEmpty) {
      return 'Preencha todos os campos';
    }
    if (!validarEmail(email)) return 'E-mail inválido';
    if (senha != confirmacaoSenha) return 'As senhas não coincidem';

    final erroSenha = validarSenhaForte(senha);
    if (erroSenha != null) return erroSenha;

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      await _db.collection('usuarios').doc(cred.user!.uid).set({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'dataCadastro': FieldValue.serverTimestamp(),
        'plano': 'gratuito',
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _traduzirErro(e.code);
    }
  }

  // ── RF004: Atualização e Leitura de Perfil ────────────────────────────────

  Future<Map<String, dynamic>?> obterDadosUsuario() async {
    if (usuarioAtual == null) return null;
    try {
      final doc = await _db.collection('usuarios').doc(usuarioAtual!.uid).get();
      return doc.data();
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      return null;
    }
  }

  Future<String?> atualizarPerfil(String nome, String telefone) async {
    if (usuarioAtual == null) return 'Usuário não logado';
    try {
      await _db.collection('usuarios').doc(usuarioAtual!.uid).update({
        'nome': nome,
        'telefone': telefone,
      });
      return null; // Sucesso
    } catch (e) {
      return 'Erro ao atualizar perfil: $e';
    }
  }

  // ── Sessão ────────────────────────────────────────────────────────────────

  Future<bool> estaLogado() async => _auth.currentUser != null;

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Aviso: Erro ao deslogar do Google (ignorado): $e');
    }
    await _auth.signOut();
  }

  // ── Util ──────────────────────────────────────────────────────────────────

  String _traduzirErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'email-already-in-use':
        return 'E-mail já cadastrado';
      case 'invalid-email':
        return 'E-mail inválido';
      case 'weak-password':
        return 'Senha muito fraca';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente mais tarde';
      case 'network-request-failed':
        return 'Sem conexão com a internet';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos';
      default:
        return 'Erro: $code';
    }
  }
}
