import 'package:flutter/material.dart';
import '../controller/perfil_controller.dart';

class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  final PerfilController _controller = PerfilController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Ícone do Lápis no topo
          IconButton(
            icon: Icon(_controller.isEditing ? Icons.close : Icons.edit),
            tooltip: _controller.isEditing ? 'Cancelar' : 'Editar Perfil',
            onPressed: _controller.toggleEdit,
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, size: 50, color: Colors.blue.shade800),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _controller.nomeController,
                            readOnly: !_controller.isEditing, // Trava o campo se não estiver editando
                            decoration: InputDecoration(
                              labelText: 'Nome Completo',
                              filled: !_controller.isEditing,
                              fillColor: Colors.grey.shade100, // Fica cinza quando travado
                              prefixIcon: Icon(Icons.person_outline, color: Colors.blue[800]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _controller.telefoneController,
                            readOnly: !_controller.isEditing,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Telefone',
                              filled: !_controller.isEditing,
                              fillColor: Colors.grey.shade100,
                              prefixIcon: Icon(Icons.phone_outlined, color: Colors.blue[800]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Mostra o botão de Salvar APENAS se estiver no modo edição
                  if (_controller.isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final sucesso = await _controller.salvarAlteracoes();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Row(
                                  children: [
                                    Icon(sucesso ? Icons.check_circle : Icons.error, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(sucesso ? 'Perfil atualizado com sucesso!' : 'Erro ao atualizar.'),
                                  ],
                                ),
                                backgroundColor: sucesso ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            );
                          }
                        },
                        child: const Text('Salvar Alterações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}