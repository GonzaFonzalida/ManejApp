import 'package:url_launcher/url_launcher.dart';

String? normalizeWhatsAppNumber(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty || !RegExp(r'^(?:\+|00)[0-9\s().-]+$').hasMatch(raw)) {
    return null;
  }

  final withPlus = raw.startsWith('00') ? '+${raw.substring(2)}' : raw;
  final digits = withPlus.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 8 || digits.length > 15 || digits.startsWith('0')) {
    return null;
  }
  return '+$digits';
}

String? validateWhatsAppNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El WhatsApp es requerido';
  }
  if (normalizeWhatsAppNumber(value) == null) {
    return 'Usá código de país, por ejemplo +54 9 11 1234 5678';
  }
  return null;
}

Future<bool> openWhatsAppLaunchUrl(String? value) async {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null || uri.scheme != 'https' || uri.host != 'wa.me') {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
