import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manejapp/screens/admin_mobile_notice_screen.dart';
import 'package:manejapp/screens/instructor_dashboard_screen.dart';
import 'package:manejapp/screens/instructor_onboarding_hub_screen.dart';
import 'package:manejapp/screens/login_screen.dart';
import 'package:manejapp/screens/choose_role_screen.dart';
import 'package:manejapp/screens/student_dashboard_screen.dart';
import 'package:manejapp/services/session_manager.dart';
import 'package:manejapp/utils/role_router.dart';

/// Campos requeridos por [RoleRouter.hasUploadedAllDocs] antes de evaluar perfil completo.
Map<String, dynamic> _instructorWithAllDocs(Map<String, dynamic> extra) => {
      'dobleComandoImg': 'https://example.com/dc',
      'seguroImg': 'https://example.com/sg',
      'vtvImg': 'https://example.com/vtv',
      'reincidenciaImg': 'https://example.com/re',
      'licenciaImg': 'https://example.com/lic',
      ...extra,
    };

/// Perfil básico completo (Track 2) sin exigir listado; opcional `publishable` en extra.
Map<String, dynamic> _instructorHubComplete(Map<String, dynamic> extra) =>
    _instructorWithAllDocs({
      'licenseNumber': '123',
      'experienceYears': 1,
      'lat': -34.6,
      'lng': -58.4,
      'isListed': false,
      'bio': 'Instructor profesional',
      'hourlyRate': 5000,
      'user': <String, dynamic>{
        'profileImage': '/uploads/face.jpg',
        'phoneNumber': '+5491122334455',
      },
      ...extra,
    });

List<Map<String, String>> _allDocsPendingReviews() => [
      {'documentType': 'dobleComandoImg', 'status': 'PENDING_REVIEW'},
      {'documentType': 'seguroImg', 'status': 'PENDING_REVIEW'},
      {'documentType': 'vtvImg', 'status': 'PENDING_REVIEW'},
      {'documentType': 'reincidenciaImg', 'status': 'PENDING_REVIEW'},
      {'documentType': 'licenciaImg', 'status': 'PENDING_REVIEW'},
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoleRouter', () {
    test('A: token null → Login', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (_) async => null,
      );
      final route = await RoleRouter.resolveInitialRoute(overrides: overrides);
      expect(route, LoginScreen.routeName);
    });

    test('B: token ok + role STUDENT sin completar perfil → ChooseRole',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async {
          if (key == 'auth_token') return 'fake-token';
          if (key == 'user_id') return '1';
          return null;
        },
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'STUDENT'},
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, ChooseRoleScreen.routeName);
    });

    test('B2: token ok + role STUDENT y perfil completado → StudentDashboard',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async {
          if (key == 'auth_token') return 'fake-token';
          if (key == 'user_id') return '1';
          if (key == kChooseRoleCompletedKey) return '1';
          if (key == kStudentOnboardingV1DoneKey) return '1';
          return null;
        },
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'STUDENT'},
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, StudentDashboardScreen.routeName);
    });

    test('B2a: alumno sin onboarding v1 → /student_onboarding_v1', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async {
          if (key == 'auth_token') return 'fake-token';
          if (key == 'user_id') return '1';
          if (key == kChooseRoleCompletedKey) return '1';
          return null;
        },
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {
          'role': 'STUDENT',
          'phoneNumber': '',
          'location': '',
        },
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, '/student_onboarding_v1');
    });

    test('B2b: alumno legacy teléfono+zona migra onboarding y va a dashboard',
        () async {
      final mem = <String, String>{
        'auth_token': 't',
        'user_id': '1',
        kChooseRoleCompletedKey: '1',
      };
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => mem[key],
        storageWrite: (key, value) async {
          mem[key] = value;
        },
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {
          'role': 'STUDENT',
          'phoneNumber': '+5491122334455',
          'location': 'Palermo, CABA',
        },
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, StudentDashboardScreen.routeName);
      expect(mem[kStudentOnboardingV1DoneKey], '1');
    });

    test(
        'C: token ok + role INSTRUCTOR + sin documentos → InstructorOnboardingHub',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => {
          'licenseNumber': '123',
          'experienceYears': 1,
        },
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorOnboardingHubScreen.routeName);
    });

    test(
        'C2: token ok + role INSTRUCTOR + docs ok + perfil incompleto → InstructorOnboardingHub',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => _instructorWithAllDocs({
          'licenseNumber': '123',
          'experienceYears': 1,
          'lat': null,
          'lng': null,
          'isListed': null,
        }),
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorOnboardingHubScreen.routeName);
    });

    test(
        'C3: token ok + role INSTRUCTOR + docs y perfil ok aunque isValid false → InstructorOnboardingHub',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => _instructorHubComplete({
          'isValid': false,
          'publishable': false,
        }),
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorOnboardingHubScreen.routeName);
    });

    test(
        'C3b: docs en PENDING_REVIEW, perfil básico completo e isValid → InstructorOnboardingHub',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => _instructorHubComplete({
          'isValid': true,
          'publishable': false,
          'documentReviews': _allDocsPendingReviews(),
        }),
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorOnboardingHubScreen.routeName);
    });

    test('C4: documento rechazado → InstructorOnboardingHub', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => _instructorHubComplete({
          'isValid': true,
          'documentReviews': [
            {'documentType': 'licenciaImg', 'status': 'REJECTED'},
          ],
        }),
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorOnboardingHubScreen.routeName);
    });

    test('C5: sin bio → InstructorOnboardingHub', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => _instructorHubComplete({
          'isValid': true,
          'bio': '',
        }),
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorOnboardingHubScreen.routeName);
    });

    test(
        'D: token ok + role INSTRUCTOR + completo + aprobado → InstructorDashboard',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => _instructorHubComplete({
          'isValid': true,
          'publishable': true,
          'isListed': true,
        }),
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorDashboardScreen.routeName);
    });

    test('E: auth/me session expired → Login', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'fake-token',
        'user_id': '1',
      });
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async => throw const SessionExpiredException(),
        apiGetUserProfile: (_) async => {'role': 'STUDENT'},
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, LoginScreen.routeName);
    });

    test('E2: auth/me network error → relanza excepción', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async => throw Exception('auth/me failed'),
        apiGetUserProfile: (_) async => {'role': 'STUDENT'},
        apiGetInstructorMeOrNull: () async => null,
      );
      expect(
        () => RoleRouter.resolveRouteForCurrentUser(
            context: 'test', overrides: overrides),
        throwsA(isA<Exception>()),
      );
    });

    test('ADMIN → AdminMobileNoticeScreen (V1 móvil)', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token'
            ? 'fake-token'
            : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'ADMIN'},
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, AdminMobileNoticeScreen.routeName);
    });

    test(
        'F: JWT stale (DB role INSTRUCTOR) → instructor dashboard si activación real',
        () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async =>
            key == 'auth_token' ? 'stale-jwt' : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => _instructorHubComplete({
          'isValid': true,
          'publishable': true,
          'isListed': true,
        }),
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorDashboardScreen.routeName);
    });
  });
}
