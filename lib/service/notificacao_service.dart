import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacaoService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    // Tiramos os "const" daqui para evitar conflito de versão
    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    
    var initializationSettingsLinux = const LinuxInitializationSettings(defaultActionName: 'Abrir notificação');

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> mostrarAlertaAmeaca(String titulo, String corpo) async {
    var androidDetails = const AndroidNotificationDetails(
      'quantum_guard_alertas', 
      'Alertas de Segurança', 
      channelDescription: 'Avisa quando uma ameaça for bloqueada',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    var platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(id: 0, title: titulo, body: corpo, notificationDetails: platformDetails);
  }
}