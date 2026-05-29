import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ⚠️ Garanta que esta importação está exatamente assim:
import 'package:google_sign_in/google_sign_in.dart';

class EmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  Future<Map<String, dynamic>> escanearEmails({int maxEmails = 100}) async {
    try {
      await _initializeGoogleSignIn();
      final List<String> scopes = <String>[
        'https://www.googleapis.com/auth/gmail.readonly',
        'https://www.googleapis.com/auth/gmail.modify',
      ];

      // Verifica se o usuário está autenticado no Firebase (necessário para
      // que a cloud function consiga identificar o uid e salvar no Firestore)
      final User? usuario = FirebaseAuth.instance.currentUser;
      if (usuario == null) {
        throw Exception(
          'Usuário não autenticado. Faça login no app antes de escanear.',
        );
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: scopes,
      );

      final GoogleSignInClientAuthorization authorization = await googleUser
          .authorizationClient
          .authorizeScopes(scopes);
      final String accessToken = authorization.accessToken;

      if (accessToken.isEmpty) {
        throw Exception("Não foi possível obter a chave de acesso do Google.");
      }

      final callable = FirebaseFunctions.instance.httpsCallable(
        'gmail_escanear_emails',
      );
      final result = await callable.call({
        'access_token': accessToken,
        'max_emails': maxEmails,
      });

      return Map<String, dynamic>.from(result.data);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Login cancelado pelo usuário.');
      }
      throw Exception('Falha no login Google: ${e.description ?? e.code}');
    } catch (e) {
      throw Exception('Falha na comunicação com o backend: $e');
    }
  }
}
