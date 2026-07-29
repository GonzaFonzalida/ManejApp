import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_manager.dart';

const _kBiometricEnabled = 'biometric_enabled';

class BiometricService {
  BiometricService._();

  static final _auth = LocalAuthentication();

  /// Whether the device has biometric hardware (Face ID, Touch ID, fingerprint).
  static Future<bool> get isDeviceSupported => _auth.isDeviceSupported();

  /// Whether the user has enrolled at least one biometric (not just hardware present).
  static Future<bool> get canAuthenticate async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Available biometric types on this device.
  static Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Human-readable label for the primary biometric (e.g. "Face ID", "Huella digital").
  static Future<String> get biometricLabel async {
    final types = await availableBiometrics;
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Huella digital';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometría';
  }

  // ─── Preference ──────────────────────────────────────────

  static Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
  }

  /// True when there is a stored session AND the user opted in to biometric unlock.
  static Future<bool> get shouldPromptOnLaunch async {
    final hasSession = await SessionManager.hasSession;
    if (!hasSession) return false;
    final enabled = await isEnabled;
    if (!enabled) return false;
    return await canAuthenticate;
  }

  // ─── Authenticate ────────────────────────────────────────

  /// Prompt the OS biometric dialog. Returns `true` on success.
  /// Never throws — failures/cancellations return `false`.
  static Future<bool> authenticate(
      {String reason = 'Desbloqueá ManejApp'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }

  /// Clears the biometric preference (called on logout).
  static Future<void> clearPreference() async {
    await setEnabled(false);
  }
}
