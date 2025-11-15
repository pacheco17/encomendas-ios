import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:badges/badges.dart' as badges;
import 'package:Encomendas/services/notification_service.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController webViewController;
  final _storage = const FlutterSecureStorage();
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    
    // ✅ ENVIAR TOKEN PARA BACKEND
    Future.delayed(const Duration(seconds: 2), () async {
      final telefone = await _storage.read(key: 'phone');
      if (telefone != null) {
        await _notificationService.enviarTokenParaBackend(telefone);
      }
    });
  }

  Future<String> _getEncryptedData() async {
    final phone = await _storage.read(key: 'phone') ?? '';
    final unit = await _storage.read(key: 'unit') ?? '';
    
    final credentials = '$phone:$unit';
    final encrypted = base64Encode(utf8.encode(credentials));
    
    debugPrint('Phone: $phone');
    debugPrint('Unit: $unit');
    debugPrint('Encrypted: $encrypted');
    
    return encrypted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encomendas'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: badges.Badge(
              badgeContent: Text(
                _notificationService.getBadgeCount().toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              showBadge: _notificationService.getBadgeCount() > 0,
              badgeStyle: badges.BadgeStyle(
                badgeColor: Colors.red,
                padding: const EdgeInsets.all(6),
              ),
              child: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getEncryptedData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final encryptedData = snapshot.data ?? '';
          final url = 'https://encomendas.tecsete.tec.br/pacheco.html?data=$encryptedData';

          return WebViewWidget(
            controller: _createWebViewController(url),
          );
        },
      ),
    );
  }

  WebViewController _createWebViewController(String url) {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
    
    return webViewController;
  }
}