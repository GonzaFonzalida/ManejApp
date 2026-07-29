import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/api_service.dart';
import '../services/config_service.dart';

Widget buildGoogleSignInButtonImpl(
  BuildContext context, {
  required VoidCallback onSuccess,
  required VoidCallback onError,
  required VoidCallback onLoadingChanged,
}) {
  final clientId = ConfigService.googleClientId;
  if (clientId == null || clientId.isEmpty) return const SizedBox.shrink();

  return _GoogleSignInButtonWeb(
    clientId: clientId,
    onSuccess: onSuccess,
    onError: onError,
    onLoadingChanged: onLoadingChanged,
  );
}

class _GoogleSignInButtonWeb extends StatefulWidget {
  final String clientId;
  final VoidCallback onSuccess;
  final VoidCallback onError;
  final VoidCallback onLoadingChanged;

  const _GoogleSignInButtonWeb({
    required this.clientId,
    required this.onSuccess,
    required this.onError,
    required this.onLoadingChanged,
  });

  @override
  State<_GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<_GoogleSignInButtonWeb> {
  GoogleSignIn? _googleSignIn;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      clientId: widget.clientId,
      scopes: const ['email', 'profile'],
    );
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    widget.onLoadingChanged();
    try {
      final account = await _googleSignIn?.signIn();
      if (account == null) {
        widget.onError();
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        widget.onError();
        return;
      }
      await ApiService.loginWithGoogle(idToken);
      if (!mounted) return;
      widget.onSuccess();
    } catch (_) {
      if (mounted) widget.onError();
    } finally {
      widget.onLoadingChanged();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _signIn,
        icon: const Icon(Icons.login, size: 20),
        label: Text(_busy ? 'Conectando…' : 'Continuar con Google'),
      ),
    );
  }
}
