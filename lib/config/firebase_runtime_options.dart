import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// En Android se usa la configuración nativa de `google-services.json`.
/// iOS y otros entornos pueden usar `--dart-define` hasta tener su archivo nativo.
abstract final class FirebaseRuntimeOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.gonzalofonzalida.manejapp',
  );

  static bool get hasExplicitConfig =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _projectId.isNotEmpty &&
      _senderId.isNotEmpty;

  static bool get hasNativeConfig =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isConfigured => hasNativeConfig || hasExplicitConfig;

  static Future<FirebaseApp> initialize() {
    if (Firebase.apps.isNotEmpty) return Future.value(Firebase.apps.first);
    if (hasExplicitConfig) {
      return Firebase.initializeApp(options: current);
    }
    return Firebase.initializeApp();
  }

  static FirebaseOptions get current => FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _senderId,
        projectId: _projectId,
        storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
        iosBundleId:
            defaultTargetPlatform == TargetPlatform.iOS ? _iosBundleId : null,
      );
}
