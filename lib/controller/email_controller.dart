import 'package:flutter/material.dart';
import '../service/email_service.dart';

class EmailController extends ChangeNotifier {
  final EmailService _emailService = EmailService();
  
  bool isLoading = false;
  // Voltando aos nomes exatos que a sua View espera:
  List<dynamic> historicoAmeacas = []; 
  int totalBloqueado = 0;
  String resumo = "";

  // Voltando ao nome exato que a sua View espera:
  Future<void> carregarDashboard() async {
    isLoading = true;
    notifyListeners();

    try {
      final dados = await _emailService.escanearEmails();
      
      if (dados.containsKey('erro')) {
        resumo = dados['erro'];
      } else {
        // Mapeando os dados novos para as variáveis antigas da View
        historicoAmeacas = dados['emails'] ?? [];
        totalBloqueado = dados['total_ameacas'] ?? 0;
        resumo = dados['resumo'] ?? "Scan concluído.";
      }
    } catch (e) {
      resumo = "Erro: $e";
      debugPrint("Erro no fluxo de Email: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}