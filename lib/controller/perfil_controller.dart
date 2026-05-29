import 'package:flutter/material.dart';
import '../service/auth_service.dart';

class PerfilController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();

  bool isLoading = true;
  bool isEditing = false; // Controla o modo do lápis

  PerfilController() {
    carregarPerfil();
  }

  // Ativa/Desativa o modo de edição
  void toggleEdit() {
    isEditing = !isEditing;
    // Se cancelar a edição, recarrega os dados originais
    if (!isEditing) {
      carregarPerfil();
    } else {
      notifyListeners();
    }
  }

  Future<void> carregarPerfil() async {
    isLoading = true;
    notifyListeners();

    final dados = await _authService.obterDadosUsuario();
    if (dados != null) {
      nomeController.text = dados['nome'] ?? '';
      telefoneController.text = dados['telefone'] ?? '';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> salvarAlteracoes() async {
    isLoading = true;
    notifyListeners();

    final erro = await _authService.atualizarPerfil(
      nomeController.text.trim(),
      telefoneController.text.trim(),
    );

    if (erro == null) {
      isEditing = false; // Fecha o modo de edição ao salvar com sucesso
    }

    isLoading = false;
    notifyListeners();

    return erro == null;
  }
}