import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import 'login_screen.dart';
import '../widgets/responsive_scroll_body.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  static const routeName = '/email-verification-pending';
  const EmailVerificationPendingScreen({super.key});

  @override
  State<EmailVerificationPendingScreen> createState() => _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState extends State<EmailVerificationPendingScreen> {
  String? _email;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email ??= ModalRoute.of(context)!.settings.arguments as String?;
    _startPolling();
    _checkVerificationStatus(); // Verificación inmediata (útil con auto-verify en desarrollo)
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkVerificationStatus();
    });
  }

  Future<void> _checkVerificationStatus() async {
    try {
      const storage = appSecureStorage;
      final userId = await storage.read(key: 'user_id');
      if (userId == null) return;

      final isVerified = await ApiService.checkVerificationStatus(userId);

      if (isVerified && mounted) {
        _timer?.cancel();
        Navigator.of(context).pushReplacementNamed('/choose_role', arguments: userId);
      }
    } catch (e) {
      debugPrint('Error checking verification: $e');
    }
  }

  Future<void> _resendVerification() async {
    if (_email == null) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.resendVerification(_email!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de verificación reenviado'),
            backgroundColor: Colors.green,
          ),
        );
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
        title: const Text('Verifica tu Email'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
      ),
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.all(16),
        centerWhenShort: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 64, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            const Text(
              'Revisa tu email y haz clic en el enlace de verificación.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text('¿No recibiste el email?', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _resendVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003087),
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Reenviar Email'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verificando automáticamente...',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed(LoginScreen.routeName),
              child: const Text('¿Ya verificaste? Ir a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
