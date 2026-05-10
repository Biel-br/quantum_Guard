import 'package:flutter/material.dart';
import '../service/email_service.dart';

class EmailController extends ChangeNotifier {
  final EmailService _emailService = EmailService();
  
  bool isLoading = false;
  List<dynamic> historicoAmeacas = [];
  int totalBloqueado = 0;

  Future<void> carregarDashboard() async {
    isLoading = true;
    notifyListeners();

    final dados = await _emailService.obterHistoricoDashboard();
    historicoAmeacas = dados['ameacas_bloqueadas'] ?? [];
    totalBloqueado = dados['total'] ?? 0;

    isLoading = false;
    notifyListeners();
  }
}