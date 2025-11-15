import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:Encomendas/screens/webview_screen.dart';
import 'package:Encomendas/screens/config_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:Encomendas/services/notification_service.dart';
import 'package:badges/badges.dart' as badges;
import 'package:firebase_analytics/firebase_analytics.dart';

const _secureStorage = FlutterSecureStorage();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Mensagem em background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('⏱️ Inicializando...');

  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.initializeFirebaseMessaging();
  
  final phone = await _secureStorage.read(key: 'phone') ?? '';
  final unit = await _secureStorage.read(key: 'unit') ?? '';
  
  await notificationService.restaurarBadgeDoServidor(phone, unit);

  debugPrint('✅ App pronto!');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Encomendas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const _HomeRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _HomeRouter extends StatefulWidget {
  const _HomeRouter();

  @override
  State<_HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<_HomeRouter> {
  late Future<bool> _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = _checkIfLoggedIn();
  }

  Future<bool> _checkIfLoggedIn() async {
    final unit = await _secureStorage.read(key: 'unit');
    final phone = await _secureStorage.read(key: 'phone');
    return unit != null && phone != null;
  }

  void _refreshLogin() {
    setState(() {
      _isLoggedIn = _checkIfLoggedIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const WebViewScreen();
        }

        return ConfigScreen(
          onConfigSaved: _refreshLogin,
        );
      },
    );
  }
}