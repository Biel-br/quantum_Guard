import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../service/virustotal_service.dart';

class HashController extends ChangeNotifier {
  // Variáveis exigidas pela View
  bool carregando = false;
  bool escaneado = false;
  bool ameaca = false;
  String status = "";
  String nomeArquivo = "";
  String hash = "";

  // Serviço da API Externa (RF007)
  final VirusTotalService _vtService = VirusTotalService();

  // 1. Função Escanear Arquivo Físico
  Future<void> selecionarEscanear() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(withData: true);
      if (result == null) return;

      carregando = true;
      escaneado = false;
      notifyListeners();

      final fileBytes = result.files.first.bytes;
      nomeArquivo = result.files.first.name;

      if (fileBytes == null) throw Exception("Não foi possível ler o arquivo.");

      final digest = sha256.convert(fileBytes);
      hash = digest.toString();

      final callable = FirebaseFunctions.instance.httpsCallable('hash_scan');
      final funcResult = await callable.call({
        'hash': hash,
        'nome': nomeArquivo,
      });

      bool ameacaInterna = funcResult.data['ameaca'] ?? false;
      String statusInterno = funcResult.data['status'] ?? "";

      final vtResult = await _vtService.consultarHash(hash);

      if (vtResult['sucesso'] == true) {
        int maliciosos = vtResult['maliciosos'];
        if (maliciosos > 0 || ameacaInterna) {
          ameaca = true;
          status =
              "⚠️ Ameaça Detectada!\nQuantum Guard: ${ameacaInterna ? 'Reprovado' : 'Limpo'}\nVirusTotal: $maliciosos motores reprovaram.";
        } else {
          ameaca = false;
          status =
              "✅ Arquivo Seguro!\nAprovado pelo Quantum Guard e VirusTotal.";
        }
      } else {
        ameaca = ameacaInterna;
        status = ameaca
            ? "⚠️ $statusInterno"
            : "✅ Arquivo Seguro!\n(Desconhecido pelo VirusTotal)";
      }
      escaneado = true;
    } catch (e) {
      status = "Erro ao escanear: $e";
      ameaca = false;
      escaneado = true;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // 2. Digitar o Hash Manualmente
  Future<void> escanearHashManual(String hashDigitado) async {
    if (hashDigitado.trim().isEmpty) return;

    carregando = true;
    escaneado = false;
    notifyListeners();

    try {
      hash = hashDigitado.trim();
      nomeArquivo = "Entrada Manual";

      final callable = FirebaseFunctions.instance.httpsCallable('hash_scan');
      final funcResult = await callable.call({
        'hash': hash,
        'nome': nomeArquivo,
      });
      bool ameacaInterna = funcResult.data['ameaca'] ?? false;
      String statusInterno = funcResult.data['status'] ?? "";

      final vtResult = await _vtService.consultarHash(hash);

      if (vtResult['sucesso'] == true) {
        int maliciosos = vtResult['maliciosos'];
        if (maliciosos > 0 || ameacaInterna) {
          ameaca = true;
          status =
              "⚠️ Ameaça Detectada!\nQuantum Guard: ${ameacaInterna ? 'Reprovado' : 'Limpo'}\nVirusTotal: $maliciosos motores reprovaram.";
        } else {
          ameaca = false;
          status =
              "✅ Arquivo Seguro!\nAprovado pelo Quantum Guard e VirusTotal.";
        }
      } else {
        ameaca = ameacaInterna;
        status = ameaca
            ? "⚠️ $statusInterno"
            : "✅ Arquivo Seguro!\n(Desconhecido pelo VirusTotal)";
      }
      escaneado = true;
    } catch (e) {
      status = "Erro ao escanear: $e";
      ameaca = false;
      escaneado = true;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  // 3. Função de Limpar a Tela
  void limpar() {
    carregando = false;
    escaneado = false;
    ameaca = false;
    status = "";
    nomeArquivo = "";
    hash = "";
    notifyListeners();
  }
}
