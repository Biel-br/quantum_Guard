import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controller/cofre_controller.dart';

/// RF005 — StreamBuilder + ListView para o cofre em tempo real
/// RF004 — edição de entradas existentes
class CofreView extends StatefulWidget {
  const CofreView({super.key});

  @override
  State<CofreView> createState() => _CofreViewState();
}

class _CofreViewState extends State<CofreView> {
  final ctrl = GetIt.I.get<CofreController>();

  // 1. Crie uma função nomeada
  void _atualizarTela() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // 2. Adicione a função nomeada
    ctrl.addListener(_atualizarTela);
  }

  // 3. Sobrescreva o dispose para remover o listener
  @override
  void dispose() {
    ctrl.removeListener(_atualizarTela);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cofre de Senhas',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // RF005 — StreamBuilder consome "cofre_senhas" em tempo real
      body: StreamBuilder<QuerySnapshot>(
        stream: ctrl.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) return _buildVazio();

          // RF005 — ListView.builder exibe os docs em tempo real
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildCard(doc.id, data);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _dialogFormulario(context, null, null),
      ),
    );
  }

  Widget _buildVazio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhuma senha salva',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Toque no + para adicionar',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCard(String docId, Map<String, dynamic> data) {
    final senhaVisivel = ctrl.senhaVisivel(docId);
    final senhaCodificada = data['senha'] as String? ?? '';
    final senhaTexto =
        senhaVisivel ? ctrl.getSenha(senhaCodificada) : '••••••••';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Site + ações
            Row(
              children: [
                const Icon(Icons.language, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['site'] ?? '',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // RF004 — botão editar
                IconButton(
                  icon:
                      const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () =>
                      _dialogFormulario(context, docId, data),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  onPressed: () => _confirmarRemover(context, docId),
                ),
              ],
            ),

            // Usuário
            if ((data['usuario'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(data['usuario'] ?? '',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],

            // Anotação (campo extra — RF003)
            if ((data['anotacao'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.note_outlined,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(data['anotacao'] ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Senha
            Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(senhaTexto, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    senhaVisivel
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => ctrl.toggleSenha(docId),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.copy, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: ctrl.getSenha(senhaCodificada)));
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
  }

  // ── Formulário (inserção RF003 e edição RF004) ────────────────────────────

  void _dialogFormulario(BuildContext context, String? docId,
      Map<String, dynamic>? dadosExistentes) {
    final editando = docId != null;
    if (editando && dadosExistentes != null) {
      ctrl.preencherParaEdicao(dadosExistentes);
    } else {
      ctrl.limparCampos();
    }

    bool senhaOculta = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            editando ? 'Editar Senha' : 'Nova Senha',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCampo(ctrl.txtSite, 'Site / Aplicativo',
                    Icons.language),
                const SizedBox(height: 10),
                _buildCampo(ctrl.txtUsuario, 'Usuário / Email',
                    Icons.person_outline),
                const SizedBox(height: 10),
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
                      icon: Icon(senhaOculta
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDialogState(
                          () => senhaOculta = !senhaOculta),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Campo anotação — RF003 (≥5 campos)
                _buildCampo(ctrl.txtAnotacao, 'Anotação (opcional)',
                    Icons.note_outlined),
                if (ctrl.erro != null) ...[
                  const SizedBox(height: 8),
                  Text(ctrl.erro!,
                      style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
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
              onPressed: ctrl.carregando
                  ? null
                  : () async {
                      bool sucesso;
                      if (editando) {
                        sucesso = await ctrl.atualizar(docId!);
                      } else {
                        sucesso = await ctrl.adicionar();
                      }
                      if (sucesso && mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(editando
                                ? 'Senha atualizada!'
                                : 'Senha salva!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
              child: ctrl.carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(editando ? 'Atualizar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo(
      TextEditingController controller, String label, IconData icone) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icone),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: InputBorder.none,
      ),
    );
  }

  void _confirmarRemover(BuildContext context, String docId) {
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
            onPressed: () async {
              await ctrl.remover(docId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}