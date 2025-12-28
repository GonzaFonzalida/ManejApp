import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  static const routeName = '/verify-email';
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token == null) {
      _token = ModalRoute.of(context)!.settings.arguments as String?;
      if (_token != null) _verifyEmail();
    }
  }

  Future<void> _verifyEmail() async {
    if (_token == null) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.verifyEmail(_token!);

      if (mounted) {
        final storage = FlutterSecureStorage();
        final userId = await storage.read(key: 'user_id');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verificado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (userId != null) {
          Navigator.of(context).pushReplacementNamed('/choose_role', arguments: userId);
        } else {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Email'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 64, color: Colors.blue.shade700),
                  const SizedBox(height: 16),
                  const Text('Verificando tu email...', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Si no se redirige automáticamente, intenta iniciar sesión.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
