import 'package:flutter/material.dart';

class SobreView extends StatelessWidget {
  const SobreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // Logo
            Icon(Icons.security, size: 100, color: Colors.blue.shade900),
            const SizedBox(height: 12),
            Text(
              'AntiVirus App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const Text(
              'Versão 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // Objetivo
            _buildSecao(
              icone: Icons.info_outline,
              titulo: 'Objetivo',
              conteudo:
                'O AntiVirus App é uma aplicação de segurança digital '
                'desenvolvida para auxiliar usuários na proteção de seus '
                'dispositivos e dados. O app oferece funcionalidades como '
                'verificação de arquivos por hash, cofre de senhas criptografado, '
                'verificação de URLs maliciosas, análise de extensões de arquivos '
                'e geração de relatórios de segurança.',
            ),

            const SizedBox(height: 16),

            // Equipe
            _buildSecao(
              icone: Icons.group_outlined,
              titulo: 'Equipe de Desenvolvimento',
              conteudo: '',
              filhos: [
                _buildMembro('Gabriel', 'Desenvolvedor'),
                _buildMembro('Felipe Delchiaro', 'Desenvolvedor'),
              ],
            ),

            const SizedBox(height: 16),

            // Informações institucionais
            _buildSecao(
              icone: Icons.school_outlined,
              titulo: 'Informações Institucionais',
              conteudo: '',
              filhos: [
                _buildInfo('Disciplina', 'Programação para Dispositivos Móveis'),
                _buildInfo('Instituição', 'Fatec Ribeirão Preto'),
                _buildInfo('Professor', 'Rodrigo Plotze'),
              ],
            ),

            const SizedBox(height: 16),

            // Tecnologias
            _buildSecao(
              icone: Icons.code_outlined,
              titulo: 'Tecnologias Utilizadas',
              conteudo: '',
              filhos: [
                _buildChip('Flutter'),
                _buildChip('Dart'),
                _buildChip('GetIt'),
                _buildChip('SharedPreferences'),
                _buildChip('Crypto'),
                _buildChip('FilePicker'),
              ],
              wrap: true,
            ),

            const SizedBox(height: 32),

            // Rodapé
            Text(
              '© 2025 AntiVirus App. Todos os direitos reservados.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Seção genérica
  Widget _buildSecao({
    required IconData icone,
    required String titulo,
    required String conteudo,
    List<Widget>? filhos,
    bool wrap = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção
            Row(
              children: [
                Icon(icone, color: Colors.blue.shade900),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Conteúdo texto
            if (conteudo.isNotEmpty)
              Text(
                conteudo,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),

            // Filhos em wrap (chips)
            if (filhos != null && wrap)
              Wrap(spacing: 8, runSpacing: 8, children: filhos),

            // Filhos em coluna
            if (filhos != null && !wrap)
              Column(children: filhos),
          ],
        ),
      ),
    );
  }

  // Card de membro da equipe
  Widget _buildMembro(String nome, String papel) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(
          nome[0],
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(papel),
    );
  }

  // Linha de informação
  Widget _buildInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }

  // Chip de tecnologia
  Widget _buildChip(String label) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(color: Colors.blue.shade900),
    );
  }
}