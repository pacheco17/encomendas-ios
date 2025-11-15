import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConfigScreen extends StatefulWidget {
  final VoidCallback? onConfigSaved;
  const ConfigScreen({super.key, this.onConfigSaved});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _unitController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final phone = await _storage.read(key: 'phone');
    final unit = await _storage.read(key: 'unit');
    if (phone != null) _phoneController.text = phone;
    if (unit != null) _unitController.text = unit;
    setState(() {});
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      await _storage.write(key: 'phone', value: _phoneController.text);
      await _storage.write(key: 'unit', value: _unitController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salvo com sucesso!')),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) widget.onConfigSaved?.call();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unidade'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}