import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/auth_controller.dart';
import 'home_view.dart';

class CadastroView extends StatefulWidget {
  const CadastroView({super.key});

  @override
  State<CadastroView> createState() => _CadastroViewState();
}

class _CadastroViewState extends State<CadastroView> {
  final ctrl = GetIt.I.get<AuthController>();

  @override
void initState() {
  super.initState();
  // Aguarda a tela renderizar para depois limpar os campos
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ctrl.limparCamposCadastro();
  });
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

                  // Header
                  Icon(Icons.person_add, size: 60, color: Colors.blue.shade900),
                  const SizedBox(height: 8),
                  Text(
                    'Criar Conta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nome
                  _buildCampo(
                    controller: ctrl.txtNome,
                    label: 'Nome completo',
                    icone: Icons.person_outline,
                  ),

                  const SizedBox(height: 16),

                  // Email
                  _buildCampo(
                    controller: ctrl.txtEmail,
                    label: 'E-mail',
                    icone: Icons.email_outlined,
                    tipo: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Telefone
                  _buildCampo(
                    controller: ctrl.txtTelefone,
                    label: 'Telefone',
                    icone: Icons.phone_outlined,
                    tipo: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  // Senha
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

                  const SizedBox(height: 16),

                  // Confirmação de senha
                  TextField(
                    controller: ctrl.txtConfirmacaoSenha,
                    obscureText: !ctrl.confirmacaoSenhaVisivel,
                    onChanged: (_) => ctrl.limparErro(),
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(ctrl.confirmacaoSenhaVisivel
                          ? Icons.visibility_off
                          : Icons.visibility),
                        onPressed: ctrl.toggleConfirmacaoSenha,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  // Erro
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
                          Expanded(
                            child: Text(ctrl.erro!,
                              style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botão cadastrar
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
                            final sucesso = await ctrl.cadastrar();
                            if (sucesso && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Conta criada com sucesso!'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2), // tempo de exibição
                                ),
                              );
                              // Aguarda o SnackBar aparecer antes de navegar
                              await Future.delayed(const Duration(seconds: 2));
                              if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeView(),
                                ),
                              );
                              }
                           }
                          },
                          child: const Text(
                            'Criar Conta',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  ),

                  const SizedBox(height: 16),

                  // Voltar para login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Já tem conta?'),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fazer login'),
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

  // Campo de texto padrão
  Widget _buildCampo({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    TextInputType tipo = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: tipo,
      onChanged: (_) => ctrl.limparErro(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}