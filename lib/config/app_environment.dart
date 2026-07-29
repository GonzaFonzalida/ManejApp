import 'package:flutter/foundation.dart';

/// Valores de lanzamiento configurables sin dejar datos de producción
/// escritos en el código fuente.
abstract final class AppEnvironment {
  static const supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'soporte@manejapp.app',
  );

  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const buildNumber = String.fromEnvironment('BUILD_NUMBER');

  static const _configuredAdminPanelUrl =
      String.fromEnvironment('ADMIN_PANEL_URL');

  static String get adminPanelUrl {
    if (_configuredAdminPanelUrl.isNotEmpty) return _configuredAdminPanelUrl;
    return kReleaseMode ? '' : 'http://localhost:3001';
  }

  static bool get hasAdminPanelUrl => adminPanelUrl.isNotEmpty;

  static String get versionLabel => buildNumber.isEmpty
      ? 'Versión $appVersion'
      : 'Versión $appVersion ($buildNumber)';
}
