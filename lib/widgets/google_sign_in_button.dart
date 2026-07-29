import 'package:flutter/material.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart';

/// Wrapper multiplataforma:
/// - Web: renderiza Google Sign-In.
/// - No-web (Android/iOS/tests VM): widget vacío.
Widget buildGoogleSignInButton(
  BuildContext context, {
  required VoidCallback onSuccess,
  required VoidCallback onError,
  required VoidCallback onLoadingChanged,
}) {
  return buildGoogleSignInButtonImpl(
    context,
    onSuccess: onSuccess,
    onError: onError,
    onLoadingChanged: onLoadingChanged,
  );
}
