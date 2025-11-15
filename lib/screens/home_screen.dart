import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart'; // NOVO IMPORT
import 'dart:convert'; // Import para Base64 encoding
import 'package:encomendas_outubro_2025/screens/config_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = true; // Indica se o app está carregando as configurações e tentando lançar a URL
  String? _errorMessage; // Guarda a mensagem de erro

  // URL base fixa do seu site
  final String _baseUrl = 'https://encomendas.tecsete.tec.br/pacheco.html';
  String? _lastBuiltUrl; // Guarda a última URL construída para exibição

  @override
  void initState() {
    super.initState();
    _loadConfigAndLaunchUrl();
  }

  Future<void> _loadConfigAndLaunchUrl() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _lastBuiltUrl = null; // Resetar URL
    });

    String? phone = await _storage.read(key: 'phone');
    String? unit = await _storage.read(key: 'unit');

    if (!mounted) return; // Garante que o widget ainda está ativo

    if (phone != null && unit != null && phone.isNotEmpty && unit.isNotEmpty) {
      final String rawData = '$phone:$unit';
      final String encodedData = base64.encode(utf8.encode(rawData));
      final String finalUrl = '$_baseUrl?data=$encodedData';

      debugPrint('Attempting to launch URL: $finalUrl');

      if (!mounted) return;
      setState(() {
        _lastBuiltUrl = finalUrl; // Guarda a URL para exibir
      });

      try {
        // Tentativa de lançar a URL
        // Para web, isso geralmente abre uma nova aba/janela.
        // Para mobile, pode abrir um navegador externo ou um WebView in-app.
        bool launched = await launchUrl(
          Uri.parse(finalUrl),
          mode: LaunchMode.platformDefault, // Abre de forma padrão para cada plataforma
        );

        if (!launched) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Não foi possível abrir a URL: $finalUrl';
            _isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          // Se lançou com sucesso, não há mais "carregamento" dentro do app.
          // O usuário interagirá com a nova aba/navegador externo.
        }
      } catch (e) {
        debugPrint('Error launching URL: $e');
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Erro ao tentar abrir a URL: $e';
          _isLoading = false;
        });
      }
    } else {
      // Se Telefone ou Unidade não estão configurados
      debugPrint('No phone or unit configured. Navigating to ConfigScreen.');
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Não está carregando, mas esperando configuração
        _errorMessage = 'Telefone ou Unidade não configurados.';
      });
      _navigateToConfig();
    }
  }

  void _navigateToConfig() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfigScreen()),
    );
    // Após retornar da ConfigScreen, tenta carregar tudo novamente
    _loadConfigAndLaunchUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encomendas'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToConfig,
          ),
          if (!_isLoading && _errorMessage == null && _lastBuiltUrl != null) // Mostra o refresh se não houver erro e a URL foi lançada
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadConfigAndLaunchUrl, // Relança a URL
            ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text('Carregando configurações e abrindo sistema...'),
              ] else if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadConfigAndLaunchUrl,
                  child: const Text('Tentar Novamente'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _navigateToConfig,
                  child: const Text('Configurar Telefone/Unidade'),
                ),
              ] else ...[
                // Se tudo deu certo e a URL foi lançada
                const Text(
                  'Sistema de Entregas aberto!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verifique a nova aba do navegador. \nURL utilizada: ${_lastBuiltUrl ?? "N/A"}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadConfigAndLaunchUrl,
                  child: const Text('Abrir Novamente'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _navigateToConfig,
                  child: const Text('Alterar Configurações'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}