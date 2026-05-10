import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:device_preview/device_preview.dart';
import 'package:projeto_pdm/controller/auth_controller.dart';
import 'package:projeto_pdm/view/login_view.dart';
import 'controller/hash_controller.dart';
import 'controller/cofre_controller.dart';
import 'controller/url_controller.dart';
import 'controller/extensao_controller.dart';
import 'controller/relatorio_controller.dart';
import 'controller/yara_controller.dart';
import 'controller/email_controller.dart'; 
import 'package:firebase_core/firebase_core.dart'; // <-- Importe o motor principal
import 'firebase_options.dart';
import 'service/notificacao_service.dart';

void main() async{
  // 1. Garante que o Flutter está pronto antes de chamar código nativo
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Inicializa as notificações que criamos antes
  await NotificacaoService.inicializar();    

  // 3. Inicializa o Firebase com as opções geradas para o seu Linux/Android/Web
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _setupGetIt();
  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
}

void _setupGetIt() {
  GetIt.I.registerSingleton(RelatorioController());
  GetIt.I.registerSingleton(AuthController());
  GetIt.I.registerSingleton(HashController());
  GetIt.I.registerSingleton(CofreController());
  GetIt.I.registerSingleton(UrlController());
  GetIt.I.registerSingleton(ExtensaoController());
  GetIt.I.registerSingleton(YaraController());
  GetIt.I.registerSingleton(EmailController());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AV App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade900),
      ),
      home: const LoginView(),
    );
  }
}
