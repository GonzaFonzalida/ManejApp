import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../services/api_service.dart';
import '../services/config_service.dart';

/// Reusable Google Sign-In flow shared by login and register screens.
///
/// 1. Checks that `googleClientId` is configured.
/// 2. Launches the Google prompt via `google_sign_in`.
/// 3. Sends the `idToken` to the backend (`/auth/google`).
/// 4. [ApiService.loginWithGoogle] saves the session via [SessionManager].
///
/// Returns the backend response map, or `null` if the user cancelled.
class GoogleAuthHelper {
  GoogleAuthHelper._();

  static Future<Map<String, dynamic>?> signIn() async {
    final clientId = ConfigService.googleClientId;
    if (clientId == null || clientId.isEmpty) {
      throw Exception(
        'Login con Google no está configurado. Contactá al administrador.',
      );
    }

    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? clientId : null,
      serverClientId: clientId,
    );

    final account = await googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception('No se obtuvo el token de Google');
    }

    return ApiService.loginWithGoogle(idToken);
  }

  /// Sign out from the Google SDK (does NOT touch the backend session).
  /// Call this during logout to clear the cached Google account so the
  /// user sees the account chooser next time.
  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
  }
}
