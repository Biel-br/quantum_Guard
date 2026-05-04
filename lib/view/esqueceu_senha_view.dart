import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../controller/auth_controller.dart';

class EsqueceuSenhaView extends StatefulWidget {
  const EsqueceuSenhaView({super.key});

  @override
  State<EsqueceuSenhaView> createState() => _EsqueceuSenhaViewState();
}

class _EsqueceuSenhaViewState extends State<EsqueceuSenhaView> {
  final ctrl = GetIt.I.get<AuthController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
    ctrl.limparRecuperacao();
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
              child: ctrl.recuperacaoEnviada
                ? _buildSucesso(context)
                : _buildFormulario(context),
            ),
          ),
        ),
      ),
    );
  }

  // Tela de sucesso após envio
  Widget _buildSucesso(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_read, size: 80, color: Colors.green.shade600),
        const SizedBox(height: 16),
        const Text(
          'E-mail enviado!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Enviamos as instruções de recuperação para:\n${ctrl.txtEmailRecuperacao.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar ao Login'),
        ),
      ],
    );
  }

  // Formulário de recuperação
  Widget _buildFormulario(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // Header
        Icon(Icons.lock_reset, size: 70, color: Colors.blue.shade900),
        const SizedBox(height: 8),
        Text(
          'Recuperar Senha',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Informe seu e-mail cadastrado e\nenvaremos as instruções de recuperação.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),

        const SizedBox(height: 32),

        // Campo email
        TextField(
          controller: ctrl.txtEmailRecuperacao,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => ctrl.limparErro(),
          decoration: InputDecoration(
            labelText: 'E-mail cadastrado',
            prefixIcon: const Icon(Icons.email_outlined),
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
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ctrl.erro!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Botão recuperar
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
                onPressed: ctrl.recuperarSenha,
                child: const Text(
                  'Recuperar Senha',
                  style: TextStyle(fontSize: 16),
                ),
              ),
        ),

        const SizedBox(height: 16),

        // Voltar
        TextButton.icon(
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar ao Login'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
