import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';


class NotificationService {
  static bool _jaProcessouNotificacao = false;
  
  int _ultimoBadgeAtualizado = -1; 
  
  static final NotificationService _instance = NotificationService._internal();
  static const _secureStorage = FlutterSecureStorage();

  static int _badgeCount = 0;
  static Function? _onBadgeChanged;
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<int> _badgeStreamController =
      StreamController<int>.broadcast();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Define callback para quando badge mudar
  void setOnBadgeChanged(Function callback) {
    _onBadgeChanged = callback;
  }

  /// Obtém o stream do badge
  Stream<int> getBadgeStream() {
    return _badgeStreamController.stream;
  }

  /// Obtém o token FCM do Firebase Messaging
  Future<String?> getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _secureStorage.write(key: 'fcm_token', value: token);
      }
      return token;
    } catch (e) {
      debugPrint('Erro ao obter FCM token: $e');
      return null;
    }
  }

  /// Obtém o token armazenado anteriormente
  Future<String?> getStoredFCMToken() async {
    try {
      return await _secureStorage.read(key: 'fcm_token');
    } catch (e) {
      debugPrint('Erro ao ler FCM token armazenado: $e');
      return null;
    }
  }

  /// Obtém o número da unidade armazenado
  Future<String?> getUnit() async {
    try {
      return await _secureStorage.read(key: 'unit');
    } catch (e) {
      debugPrint('Erro ao ler unit: $e');
      return null;
    }
  }

  /// Obtém o telefone armazenado
  Future<String?> getPhone() async {
    try {
      return await _secureStorage.read(key: 'phone');
    } catch (e) {
      debugPrint('Erro ao ler phone: $e');
      return null;
    }
  }

  /// ✅ ATUALIZA BADGE NO ÍCONE (sistema operacional)
  Future<void> _atualizarBadgeIcone(int numero) async {
    try {
      final platform = MethodChannel('com.example.encomendas_outubro_2025/badge');
      
      if (numero > 0) {
        await platform.invokeMethod('setBadge', {'count': numero});
        debugPrint('✅ Badge do ícone atualizado: $numero');
      } else {
        await platform.invokeMethod('removeBadge');
        debugPrint('✅ Badge do ícone removido');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao atualizar badge do ícone: $e');
    }
  }


  Future<void> restaurarBadge() async {
    final badge = await _obterBadgeStorage();
    _badgeCount = badge;
    
    if (badge > 0) {
      debugPrint('🔄 Badge restaurado: $badge');
      await _atualizarBadgeIcone(badge);
    }
  }


  Future<int> _obterBadgeStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('badge_count') ?? 0;
  }


  /// Obtém o valor atual do badge
  int getBadgeCount() {
    return _badgeCount;
  }


  void _handleNotification(RemoteMessage message) {
    final data = message.data;
    final mensagem = data['mensagem'] ?? '';
    final tipo = data['tipo'] ?? '';
    final phone = data['phone'] ?? '';  // ← PEGA DO PAYLOAD
    final unit = data['unit'] ?? '';    // ← PEGA DO PAYLOAD

    debugPrint('════════════════════════════════════════');
    debugPrint('📦 Data completo: $data');
    debugPrint('📦 Mensagem: "$mensagem"');
    debugPrint('📦 Tipo: "$tipo"');
    debugPrint('📦 Phone: "$phone"');
    debugPrint('📦 Unit: "$unit"');
    debugPrint('════════════════════════════════════════');

    // ✅ Consulta a API se recebeu phone e unit
    if (phone.isNotEmpty && unit.isNotEmpty) {
      debugPrint('🔄 Consultando servidor com phone=$phone, unit=$unit');
      restaurarBadgeDoServidor(phone, unit);
    } else {
      debugPrint('⚠️ Phone ou Unit faltando na notificação!');
    }
  }


  Future<void> restaurarBadgeDoServidor(String phone, String unit) async {
    try {
      // ✅ Ignora erro de certificado
      HttpOverrides.global = MyHttpOverrides();
      
      final response = await http.get(
        Uri.parse('https://interno.tecsete.tec.br/api/badge-status.php?phone=$phone&unit=$unit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _badgeCount = data['badge'] ?? 0;
        final mensagem = data['mensagem'] ?? '';
        
        debugPrint('📡 Badge do servidor: $_badgeCount');
        debugPrint('📡 Mensagem: $mensagem');
        
        await salvarBadgeNoStorage(_badgeCount);
        await _atualizarBadgeIcone(_badgeCount);
      } else {
        debugPrint('⚠️ Erro na resposta: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao buscar badge do servidor: $e');
    }
  }


  /// Inicializa notificações locais
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Mostra notificação local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required String tipo,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'encomendas_channel',
      'Notificações de Encomendas',
      channelDescription: 'Notificações de encomendas disponíveis',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );

    debugPrint('? Notificação local mostrada: ${title} (tipo: $tipo)');
  }

  /// Inicializa as notificações do Firebase
  Future<void> initializeFirebaseMessaging() async {
    try {
      // Inicializa notificações locais
      await initializeLocalNotifications();

      // Solicita permissão
      await FirebaseMessaging.instance.requestPermission();

      // ✅ LISTENER: Mensagens em FOREGROUND (app ABERTO)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📨 Mensagem recebida em foreground');
        _handleNotification(message);
      });

      // ✅ LISTENER: App aberto a partir de notificação
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔗 App aberto a partir de notificação');

        if (_jaProcessouNotificacao) {
          debugPrint('⏭️ Notificação já foi processada, ignorando');
          return;
        }
        _jaProcessouNotificacao = true;
        _handleNotification(message);
      });

      debugPrint('✅ Firebase Messaging inicializado');
    } catch (e) {
      debugPrint('❌ Erro ao inicializar Firebase Messaging: $e');
    }
  }




  Future<bool> enviarTokenParaBackend(String telefone) async {
    try {
      final token = await getFCMToken();
      
      if (token == null) {
        debugPrint('❌ Token FCM não disponível');
        return false;
      }

      final origem = await _secureStorage.read(key: 'unit');
      
      if (origem == null) {
        debugPrint('❌ Origem não configurada');
        return false;
      }

      final url = Uri.parse('https://cae.tecsete.tec.br/save-fcm-token.php');
      
      final body = jsonEncode({
        'origem': origem,
        'telefone': telefone,
        'token': token,
        'plataforma': 'android',
      });
      
      debugPrint('📤 Enviando: $body');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 3));

      debugPrint('📥 Resposta: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM enviado com sucesso para backend');
        return true;
      } else {
        debugPrint('⚠️ Erro ao enviar token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar token para backend: $e');
      return false;
    }
  }

  Future<void> salvarBadgeNoStorage(int badge) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('badge_count', badge);
    debugPrint('💾 Badge salvo no storage: $badge');
  }

  Future<int> recuperarBadgeDoStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final badge = prefs.getInt('badge_count') ?? 0;
    debugPrint('📖 Badge recuperado do storage: $badge');
    return badge;
  }

}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}