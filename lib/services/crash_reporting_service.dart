import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Reporte de fallos de producción. En debug y web queda desactivado para no
/// contaminar Crashlytics con errores de desarrollo o pruebas automatizadas.
class CrashReportingService {
  CrashReportingService._();

  static bool _available = false;

  static Future<void> initialize() async {
    if (!kReleaseMode || kIsWeb || Firebase.apps.isEmpty) return;

    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = crashlytics.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        crashlytics.recordError(error, stackTrace, fatal: true);
        return true;
      };
      _available = true;
    } catch (error, stackTrace) {
      debugPrint('Crashlytics no pudo inicializarse: $error\n$stackTrace');
    }
  }

  static Future<void> recordNonFatal(
    Object error,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (!_available) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }
}
