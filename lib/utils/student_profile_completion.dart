// Cálculo de completitud del perfil de alumno y prompts contextuales.
// Usa el mapa devuelto por ApiService.getUserProfile (student.experienceLevel, profileImage).

import 'package:manejapp/utils/whatsapp.dart';

class ProfilePrompt {
  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;

  const ProfilePrompt({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });
}

class StudentProfileCompletion {
  StudentProfileCompletion._();

  static int? _experienceLevel(Map<String, dynamic> profile) {
    final top = profile['experienceLevel'];
    if (top is int) return top;
    if (top is num) return top.toInt();
    final s = profile['student'];
    if (s is Map) {
      final e = s['experienceLevel'];
      if (e is int) return e;
      if (e is num) return e.toInt();
    }
    return int.tryParse('$top');
  }

  /// Usuarios que registraron con el formulario largo (teléfono + ubicación): no forzar wizard.
  static bool shouldSkipProgressiveOnboarding(Map<String, dynamic> profile) {
    final phone = (profile['phoneNumber'] ?? '').toString().trim();
    final loc = (profile['location'] ?? '').toString().trim();
    return normalizeWhatsAppNumber(phone) != null && loc.length >= 3;
  }

  /// 4 bloques de 25%: nivel, teléfono, ubicación, foto.
  static int completionPercent(Map<String, dynamic> profile) {
    var pts = 0;
    final level = _experienceLevel(profile) ?? 0;
    if (level >= 1) pts += 25;

    final phone = (profile['phoneNumber'] ?? '').toString().trim();
    if (normalizeWhatsAppNumber(phone) != null) pts += 25;

    final loc = (profile['location'] ?? '').toString().trim();
    if (loc.length >= 3) pts += 25;

    final img = profile['profileImage']?.toString().trim();
    if (img != null && img.isNotEmpty) pts += 25;

    return pts.clamp(0, 100);
  }

  static List<ProfilePrompt> promptsFor(Map<String, dynamic> profile) {
    final list = <ProfilePrompt>[];
    final phone = (profile['phoneNumber'] ?? '').toString().trim();
    if (normalizeWhatsAppNumber(phone) == null) {
      list.add(
        const ProfilePrompt(
          id: 'phone',
          title: 'Agregá tu WhatsApp',
          subtitle:
              'Se habilita con tu instructor únicamente cuando la clase está confirmada.',
          actionLabel: 'Completar',
        ),
      );
    }
    final loc = (profile['location'] ?? '').toString().trim();
    if (loc.length < 3) {
      list.add(
        const ProfilePrompt(
          id: 'location',
          title: 'Indicá tu zona',
          subtitle: 'Mejoramos las sugerencias de instructores cerca tuyo.',
          actionLabel: 'Completar',
        ),
      );
    }
    final img = profile['profileImage']?.toString().trim();
    if (img == null || img.isEmpty) {
      list.add(
        const ProfilePrompt(
          id: 'photo',
          title: 'Subí una foto de perfil',
          subtitle: 'Genera confianza al reservar clases.',
          actionLabel: 'Agregar foto',
        ),
      );
    }
    final level = _experienceLevel(profile) ?? 0;
    if (level < 1) {
      list.add(
        const ProfilePrompt(
          id: 'experience',
          title: 'Definí tu nivel de manejo',
          subtitle: 'Ayudá al instructor a preparar la clase a tu medida.',
          actionLabel: 'Elegir nivel',
        ),
      );
    }
    return list;
  }
}
