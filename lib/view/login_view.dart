import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/auth_controller.dart';
import 'home_view.dart';
import 'cadastro_view.dart';
import 'esqueceu_senha_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final ctrl = GetIt.I.get<AuthController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    width: 230,
                    height: 230,
                  ),

                  // Campo email
                  TextField(
                    controller: ctrl.txtEmail,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => ctrl.limparErro(),
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo senha
                  TextField(
                    controller: ctrl.txtSenha,
                    obscureText: !ctrl.senhaVisivel,
                    onChanged: (_) => ctrl.limparErro(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(ctrl.senhaVisivel
                          ? Icons.visibility_off
                          : Icons.visibility),
                        onPressed: ctrl.toggleSenha,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // Mensagem de erro
                  if (ctrl.erro != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                            color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(ctrl.erro!,
                            style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botão entrar
                  SizedBox(
                    width: double.infinity,
                    child: ctrl.carregando
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final sucesso = await ctrl.login();
                            if (sucesso && mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeView(),
                                ),
                              );
                            } else if (!sucesso && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ctrl.erro ?? 'Erro ao fazer login'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Entrar',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Esqueceu a senha
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EsqueceuSenhaView(),
                      ),
                    ),
                    child: const Text('Esqueceu a senha?'),
                  ),

                  // Cadastro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Não tem conta?'),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CadastroView(),
                          ),
                        ),
                        child: const Text('Cadastre-se'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}