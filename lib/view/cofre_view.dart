import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../controller/cofre_controller.dart';

class CofreView extends StatefulWidget {
  const CofreView({super.key});

  @override
  State<CofreView> createState() => _CofreViewState();
}

class _CofreViewState extends State<CofreView> {
  final ctrl = GetIt.I.get<CofreController>();

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() => setState(() {}));
    ctrl.carregar(); // ← carrega as senhas salvas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cofre de Senhas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ctrl.carregando
        ? const Center(child: CircularProgressIndicator())
        : ctrl.entradas.isEmpty
          ? _buildVazio()
          : _buildLista(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _dialogAdicionar(context),
      ),
    );
  }

  // Tela vazia
  Widget _buildVazio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma senha salva',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Toque no + para adicionar',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Lista de senhas
  Widget _buildLista() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ctrl.entradas.length,
      itemBuilder: (context, index) {
        final entrada = ctrl.entradas[index];
        final senhaVisivel = ctrl.senhaVisivel(index);
        final senha = senhaVisivel ? ctrl.getSenha(index) : '••••••••';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Site
                Row(
                  children: [
                    const Icon(Icons.language, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      entrada['site']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Botão deletar
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmarRemover(context, index),
                    ),
                  ],
                ),

                // Usuário
                if (entrada['usuario']!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(entrada['usuario']!, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                // Senha
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(senha, style: const TextStyle(fontSize: 16)),
                    const Spacer(),
                    // Mostrar/ocultar senha
                    IconButton(
                      icon: Icon(
                        senhaVisivel ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => ctrl.toggleSenha(index),
                    ),
                    // Copiar senha
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: ctrl.getSenha(index)),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Senha copiada!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dialog adicionar senha
  void _dialogAdicionar(BuildContext context) {
    bool senhaOculta = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Nova Senha',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Site
              TextField(
                controller: ctrl.txtSite,
                decoration: InputDecoration(
                  labelText: 'Site / Aplicativo',
                  prefixIcon: const Icon(Icons.language),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 10),

              // Usuário
              TextField(
                controller: ctrl.txtUsuario,
                decoration: InputDecoration(
                  labelText: 'Usuário / Email',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 10),

              // Senha
              TextField(
                controller: ctrl.txtSenha,
                obscureText: senhaOculta,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(senhaOculta ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => senhaOculta = !senhaOculta),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ctrl.limparCampos();
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ctrl.adicionar();
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog confirmar remoção
  void _confirmarRemover(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover senha?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ctrl.remover(index);
              Navigator.pop(context);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
