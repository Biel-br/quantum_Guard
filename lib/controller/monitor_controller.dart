import 'dart:async';
import 'package:flutter/material.dart';
import '../service/monitor_service.dart';

class MonitorController extends ChangeNotifier {
  final _service = MonitorService();

  Map<String, dynamic>? info;
  bool carregando = false;
  Timer? _timer;

  // Inicia atualização automática a cada 5 segundos
  void iniciar() {
    buscarInfo();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => buscarInfo());
  }

  void parar() {
    _timer?.cancel();
  }

  Future<void> buscarInfo() async {
    carregando = true;
    notifyListeners();

    try {
      info = await _service.buscarInfo();
    } catch (e) {
      info = null;
    }

    carregando = false;
    notifyListeners();
  }

  // Helpers
  String get nomeOS => info?['nome'] ?? '--';
  String get versaoOS => info?['versao_os'] ?? '--';
  String get hostname => info?['hostname'] ?? '--';
  double get usoMemoria => (info?['uso_memoria_percent'] ?? 0.0).toDouble();
  double get memoriaUsada => (info?['memoria_usada_gb'] ?? 0.0).toDouble();
  double get memoriaTotal => (info?['total_memoria_gb'] ?? 0.0).toDouble();
  int get totalCpus => info?['total_cpus'] ?? 0;
  int get totalProcessos => info?['total_processos'] ?? 0;
  int get processosSuspeitos => info?['processos_suspeitos'] ?? 0;
  List get processos => info?['processos'] ?? [];
  List get discos => info?['discos'] ?? [];
  List get redes => info?['redes'] ?? [];
}