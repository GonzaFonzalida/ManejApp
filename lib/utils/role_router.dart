import 'dart:developer' as developer;

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../services/secure_storage.dart';
import 'instructor_activation_client_status.dart';
import '../screens/admin_mobile_notice_screen.dart';
import '../screens/instructor_dashboard_screen.dart';
import '../screens/instructor_onboarding_hub_screen.dart';
import '../screens/login_screen.dart';
import '../screens/choose_role_screen.dart';
import 'student_profile_completion.dart';
import 'whatsapp.dart';

const _storage = appSecureStorage;

/// Clave en [FlutterSecureStorage]: guarda el `userId` que ya pasó por [ChooseRoleScreen] (no solo true, por si cambia la cuenta en el dispositivo).
const kChooseRoleCompletedKey = 'choose_role_completed';

/// Alumno completó el asistente progresivo (o migración legacy).
const kStudentOnboardingV1DoneKey = 'student_onboarding_v1_done';

/// Optional overrides for testing. When null, production uses [FlutterSecureStorage] and [ApiService].
class RoleRouterOverrides {
  final Future<String?> Function(String key)? storageRead;

  /// Solo usado en migración de onboarding alumno (tests pueden evitar tocar secure storage real).
  final Future<void> Function(String key, String value)? storageWrite;
  final Future<void> Function()? apiGetMe;
  final Future<Map<String, dynamic>> Function(String userId)? apiGetUserProfile;
  final Future<Map<String, dynamic>?> Function()? apiGetInstructorMeOrNull;

  const RoleRouterOverrides({
    this.storageRead,
    this.storageWrite,
    this.apiGetMe,
    this.apiGetUserProfile,
    this.apiGetInstructorMeOrNull,
  });
}

class RoleRouter {
  /// Último error capturado durante resolución de ruta (solo para debug/observabilidad).
  static String? lastRoutingError;

  static void setLastError(String? error) {
    lastRoutingError = error;
  }

  static Future<String> resolveInitialRoute(
      {RoleRouterOverrides? overrides}) async {
    final read = overrides?.storageRead ?? ((key) => _storage.read(key: key));
    final token = await read('auth_token');
    final userId = await read('user_id');

    developer.log(
      '[RoleRouter] startup: token=${token != null ? "present" : "null"} userId=$userId',
      name: 'RoleRouter',
    );

    if (token == null || userId == null) {
      developer.log('[RoleRouter] startup: → Login', name: 'RoleRouter');
      return LoginScreen.routeName;
    }

    final sessionReady =
        await SessionManager.warmUpSession(notifyOnFailure: false);
    if (!sessionReady) {
      developer.log('[RoleRouter] startup: warmUp failed → Login',
          name: 'RoleRouter');
      await SessionManager.clearSession();
      return LoginScreen.routeName;
    }

    try {
      return await resolveRouteForCurrentUser(
          context: 'startup', overrides: overrides);
    } on SessionExpiredException catch (e) {
      lastRoutingError = e.message;
      developer.log('[RoleRouter] startup: session expired → Login',
          name: 'RoleRouter');
      await SessionManager.clearSession();
      return LoginScreen.routeName;
    }
  }

  static Future<String> resolveRouteForCurrentUser({
    required String context,
    RoleRouterOverrides? overrides,
  }) async {
    developer.log('[RoleRouter] resolveRouteForCurrentUser ctx=$context',
        name: 'RoleRouter');

    final getMe = overrides?.apiGetMe ?? (() => ApiService.getMe());
    final read = overrides?.storageRead ?? ((key) => _storage.read(key: key));
    final getUserProfile =
        overrides?.apiGetUserProfile ?? ((id) => ApiService.getUserProfile(id));
    final getInstructorMeOrNull = overrides?.apiGetInstructorMeOrNull ??
        (() => ApiService.getInstructorMeOrNull());

    try {
      await getMe();
      setLastError(null);
    } on SessionExpiredException catch (e) {
      lastRoutingError = e.message;
      developer.log('[RoleRouter] ctx=$context session expired → Login',
          name: 'RoleRouter');
      await SessionManager.clearSession();
      return LoginScreen.routeName;
    } catch (e) {
      lastRoutingError = e.toString();
      developer.log('[RoleRouter] ctx=$context auth/me failed → rethrow ($e)',
          name: 'RoleRouter');
      rethrow;
    }

    final userId = await read('user_id');
    if (userId == null) {
      developer.log('[RoleRouter] ctx=$context missing user_id → Login',
          name: 'RoleRouter');
      return LoginScreen.routeName;
    }

    Map<String, dynamic> profile;
    try {
      profile = await _loadUserProfile(getUserProfile, userId);
    } on SessionExpiredException catch (e) {
      lastRoutingError = e.message;
      developer.log('[RoleRouter] ctx=$context profile session expired → Login',
          name: 'RoleRouter');
      return LoginScreen.routeName;
    }
    final role = profile['role']?.toString().toUpperCase();
    developer.log('[RoleRouter] ctx=$context role(from users/$userId)=$role',
        name: 'RoleRouter');

    if (role == 'ADMIN') return AdminMobileNoticeScreen.routeName;

    if (role == 'INSTRUCTOR') {
      Map<String, dynamic>? instructorProfile;
      try {
        instructorProfile = await getInstructorMeOrNull();
      } on SessionExpiredException catch (e) {
        lastRoutingError = e.message;
        developer.log('[RoleRouter] ctx=$context instructor/me expired → Login',
            name: 'RoleRouter');
        await SessionManager.clearSession();
        return LoginScreen.routeName;
      }
      final activation = instructorActivationClientStatus(instructorProfile);
      developer.log(
        '[RoleRouter] ctx=$context instructorProfile=${instructorProfile != null ? "present" : "null"} '
        'activation=$activation',
        name: 'RoleRouter',
      );
      // Hub hasta activación real (docs aprobados + perfil + cuenta válida + listado), misma fuente que el backend.
      if (activation != 'active') {
        developer.log(
            '[RoleRouter] ctx=$context → InstructorOnboardingHubScreen',
            name: 'RoleRouter');
        return InstructorOnboardingHubScreen.routeName;
      }

      return InstructorDashboardScreen.routeName;
    }

    final chooseDoneFor = await read(kChooseRoleCompletedKey);
    if (chooseDoneFor != userId) {
      developer.log(
        '[RoleRouter] ctx=$context STUDENT missing choose_role_completed → ${ChooseRoleScreen.routeName}',
        name: 'RoleRouter',
      );
      return ChooseRoleScreen.routeName;
    }

    var onboardingDoneFor = await read(kStudentOnboardingV1DoneKey);
    if (onboardingDoneFor != userId) {
      try {
        final studentProfile = await getUserProfile(userId);
        if (StudentProfileCompletion.shouldSkipProgressiveOnboarding(
            studentProfile)) {
          final sw = overrides?.storageWrite;
          if (sw != null) {
            await sw(kStudentOnboardingV1DoneKey, userId);
          } else {
            await _storage.write(
                key: kStudentOnboardingV1DoneKey, value: userId);
          }
          onboardingDoneFor = userId;
        }
      } catch (_) {
        /* si falla perfil, el asistente volverá a intentar */
      }
    }
    if (onboardingDoneFor != userId) {
      developer.log(
        '[RoleRouter] ctx=$context STUDENT → /student_onboarding_v1',
        name: 'RoleRouter',
      );
      return '/student_onboarding_v1';
    }

    return '/student_dashboard';
  }

  static Future<Map<String, dynamic>> _loadUserProfile(
    Future<Map<String, dynamic>> Function(String userId) getUserProfile,
    String userId,
  ) async {
    try {
      return await getUserProfile(userId);
    } on SessionExpiredException catch (e) {
      lastRoutingError = e.message;
      await SessionManager.clearSession();
      rethrow;
    }
  }

  static Future<void> markStudentOnboardingV1CompleteFor(String userId) async {
    await _storage.write(key: kStudentOnboardingV1DoneKey, value: userId);
  }

  /// Algún documento en estado REJECTED en `documentReviews`.
  static bool hasRejectedDocument(Map<String, dynamic>? instructor) {
    if (instructor == null) return false;
    final reviews = instructor['documentReviews'];
    if (reviews is! List) return false;
    for (final r in reviews) {
      if (r is Map && r['status']?.toString().toUpperCase() == 'REJECTED') {
        return true;
      }
    }
    return false;
  }

  /// Foto de perfil del usuario vinculada al instructor (`user.profileImage`).
  static bool hasInstructorProfilePhoto(Map<String, dynamic>? instructor) {
    if (instructor == null) return false;
    return _profileImageFromInstructor(instructor) != null;
  }

  static String? _profileImageFromInstructor(Map<String, dynamic> instructor) {
    final user = instructor['user'];
    if (user is! Map) return null;
    final img = user['profileImage'] ?? user['profile_image'];
    final s = img?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static bool _hourlyRatePositive(Map<String, dynamic> instructor) {
    final hourly = instructor['hourlyRate'];
    if (hourly is num) return hourly > 0;
    final p = double.tryParse(hourly?.toString() ?? '');
    return p != null && p > 0;
  }

  /// Track 2: perfil profesional mínimo **sin** exigir visibilidad en búsqueda (`isListed`).
  /// No exige número de licencia manual: la licencia se cubre con documento + revisión admin.
  /// `isListed` / publicación es Track 3 (`publishable` en API + reglas en backend).
  static bool isInstructorProfileBasicsComplete(
      Map<String, dynamic>? instructor) {
    if (instructor == null) return false;
    final exp = instructor['experienceYears'];
    final lat = instructor['lat'];
    final lng = instructor['lng'];
    final bio = instructor['bio']?.toString().trim();

    final hasExp =
        exp is num ? true : (int.tryParse(exp?.toString() ?? '') != null);
    final hasLatLng = (lat is num) && (lng is num);
    final hasBio = bio != null && bio.isNotEmpty;
    final hasHourly = _hourlyRatePositive(instructor);
    final hasPhoto = _profileImageFromInstructor(instructor) != null;
    final user = instructor['user'];
    final phone = user is Map ? user['phoneNumber']?.toString() : null;
    final hasWhatsApp = normalizeWhatsAppNumber(phone) != null;

    return hasExp &&
        hasLatLng &&
        hasBio &&
        hasHourly &&
        hasPhoto &&
        hasWhatsApp;
  }

  /// Alias histórico: mismo criterio que [isInstructorProfileBasicsComplete] (ya no incluye `isListed`).
  static bool isInstructorProfileComplete(Map<String, dynamic>? instructor) =>
      isInstructorProfileBasicsComplete(instructor);

  /// Track 3: el backend expone `publishable` en GET /instructors/me.
  static bool isInstructorPublishableFromApi(Map<String, dynamic>? instructor) {
    if (instructor == null) return false;
    final p = instructor['publishable'];
    return p is bool && p;
  }

  static bool hasUploadedAllDocs(Map<String, dynamic>? instructor) {
    if (instructor == null) return false;
    final docs = [
      'dobleComandoImg',
      'seguroImg',
      'vtvImg',
      'reincidenciaImg',
      'licenciaImg'
    ];
    for (final doc in docs) {
      if (instructor[doc] == null || instructor[doc].toString().isEmpty) {
        return false;
      }
    }
    return true;
  }
}
