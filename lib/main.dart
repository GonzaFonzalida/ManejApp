import 'dart:async';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:manejapp/screens/admin_mobile_notice_screen.dart';
import 'package:manejapp/screens/biometric_lock_screen.dart';
import 'package:manejapp/screens/choose_role_screen.dart';
import 'package:manejapp/screens/complete_instructor_profile_screen.dart';
import 'package:manejapp/screens/debug_routing_screen.dart';
import 'package:manejapp/screens/editar_perfil_screen.dart';
import 'package:manejapp/screens/email_verification_pending_screen.dart';
import 'package:manejapp/screens/forgot_password_screen.dart';
import 'package:manejapp/screens/home_screen.dart';
import 'package:manejapp/screens/instructor_car_screen.dart';
import 'package:manejapp/screens/instructor_dashboard_screen.dart';
import 'package:manejapp/screens/instructor_onboarding_hub_screen.dart';
import 'package:manejapp/screens/instructor_profile_screen.dart';
import 'package:manejapp/screens/instructor_registration_docs_screen.dart';
import 'package:manejapp/screens/login_screen.dart';
import 'package:manejapp/screens/onboarding_screen.dart';
import 'package:manejapp/screens/payment_screen.dart';
import 'package:manejapp/screens/profile_screen.dart';
import 'package:manejapp/screens/register_screen.dart';
import 'package:manejapp/screens/reset_password_screen.dart';
import 'package:manejapp/screens/reservar_clase_screen.dart';
import 'package:manejapp/screens/settings_screen.dart';
import 'package:manejapp/screens/student_classes_screen.dart';
import 'package:manejapp/screens/student_dashboard_screen.dart';
import 'package:manejapp/screens/student_payments_screen.dart';
import 'package:manejapp/screens/student_progressive_onboarding_screen.dart';
import 'package:manejapp/screens/verify_email_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/biometric_service.dart';
import 'package:manejapp/services/config_service.dart';
import 'package:manejapp/services/crash_reporting_service.dart';
import 'package:manejapp/services/deep_link_service.dart';
import 'package:manejapp/services/notification_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/services/session_manager.dart';
import 'package:manejapp/utils/role_router.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ConfigService.loadConfig();
  await NotificationService.initialize();
  await CrashReportingService.initialize();
  await initializeDateFormatting('es', null);
  await SessionManager.migrateFromLegacyStorage();
  await _requestLocationPermission();
  runApp(const MyApp());
}

Future<void> _requestLocationPermission() async {
  try {
    final storage = appSecureStorage;
    final requested = await storage.read(key: 'location_permission_requested');
    if (requested != 'true') {
      await storage.write(key: 'location_permission_requested', value: 'true');
    }
  } catch (e) {
    debugPrint('Error requesting location: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<void> _sessionExpiredSub;

  @override
  void initState() {
    super.initState();
    NotificationService.attachNavigator(_navigatorKey);
    _sessionExpiredSub = SessionManager.onSessionExpired.listen((_) {
      unawaited(NotificationService.onLogout());
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (_) => false,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.init(_navigatorKey);
      unawaited(NotificationService.consumeLaunchNotification());
    });
  }

  @override
  void dispose() {
    _sessionExpiredSub.cancel();
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ManejApp',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      /// Evita pantalla en blanco al cambiar `initialRoute` tras async (p. ej. Xcode / dispositivo físico).
      home: const _AppBootstrap(),
      routes: {
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        BiometricLockScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final target =
              args is String && args.isNotEmpty ? args : LoginScreen.routeName;
          return BiometricLockScreen(targetRoute: target);
        },
        '/login': (context) => const LoginScreen(),
        ForgotPasswordScreen.routeName: (context) =>
            const ForgotPasswordScreen(),
        ResetPasswordScreen.routeName: (context) => const ResetPasswordScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        '/choose_role': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          String? userId;
          if (arguments is String && arguments.isNotEmpty) {
            userId = arguments;
          } else if (arguments is int) {
            userId = '$arguments';
          }
          if (userId != null) {
            return ChooseRoleScreen(userId: userId);
          }
          return FutureBuilder<String?>(
            future: appSecureStorage.read(key: 'user_id'),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              final id = snap.data;
              if (id != null && id.isNotEmpty) {
                return ChooseRoleScreen(userId: id);
              }
              return const LoginScreen();
            },
          );
        },
        HomeScreen.routeName: (context) => const HomeScreen(),
        EditarPerfilScreen.routeName: (context) => const EditarPerfilScreen(),
        ReservarClaseScreen.routeName: (context) => const ReservarClaseScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        PaymentScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            final id = arguments['drivingClassId'];
            final amount = arguments['amount'];
            if (id is int && id > 0 && amount is int && amount > 0) {
              return PaymentScreen(
                drivingClassId: id,
                amount: amount,
                description: arguments['description'] as String? ?? 'Clase',
                payerEmail: arguments['payerEmail'] as String?,
              );
            }
          }
          return const _InvalidPaymentRouteScreen();
        },
        // Rutas del instructor
        InstructorDashboardScreen.routeName: (context) =>
            const InstructorDashboardScreen(),
        CompleteInstructorProfileScreen.routeName: (context) =>
            const CompleteInstructorProfileScreen(),
        InstructorRegistrationDocsScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          String? focusDocKey;
          if (args is Map) {
            final raw = args['focusDocKey'];
            if (raw is String && raw.isNotEmpty) focusDocKey = raw;
          }
          return InstructorRegistrationDocsScreen(focusDocKey: focusDocKey);
        },
        InstructorOnboardingHubScreen.routeName: (context) =>
            const InstructorOnboardingHubScreen(),
        '/instructor_car': (context) => const InstructorCarScreen(),
        InstructorProfileScreen.routeName: (ctx) {
          final args =
              ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          return InstructorProfileScreen(
            instructor: args['instructor'] as Instructor,
            instructorLocation: args['location'] as LatLng?,
          );
        },
        // Rutas del estudiante
        StudentProgressiveOnboardingScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          final uid =
              arguments is String && arguments.isNotEmpty ? arguments : null;
          return StudentProgressiveOnboardingScreen(userId: uid);
        },
        StudentDashboardScreen.routeName: (context) =>
            const StudentDashboardScreen(),
        '/student_classes': (context) => const StudentClassesScreen(),
        '/student_payments': (context) => const StudentPaymentsScreen(),
        // Admin V1: aviso web (sin panel móvil roto)
        AdminMobileNoticeScreen.routeName: (context) =>
            const AdminMobileNoticeScreen(),
        // Rutas generales
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        VerifyEmailScreen.routeName: (context) => const VerifyEmailScreen(),
        EmailVerificationPendingScreen.routeName: (context) =>
            const EmailVerificationPendingScreen(),
        if (!kReleaseMode)
          DebugRoutingScreen.routeName: (context) => const DebugRoutingScreen(),
      },
    );
  }
}

/// Pantalla mínima de arranque: resuelve sesión/ruta y reemplaza la pila con `pushReplacementNamed`.
/// Corrige pantalla en blanco cuando `initialRoute` se actualizaba tras async (MaterialApp no re-aplica bien).
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  String? _errorMessage;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_go()));
  }

  Future<void> _go() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _retrying = true;
    });

    final nav = Navigator.of(context);

    const storage = appSecureStorage;
    final firstLaunch = await storage.read(key: 'first_launch_completed');
    if (firstLaunch != 'true') {
      await storage.write(key: 'first_launch_completed', value: 'true');
      if (!mounted) return;
      nav.pushReplacementNamed(OnboardingScreen.routeName);
      return;
    }

    try {
      final route = await RoleRouter.resolveInitialRoute();
      debugPrint('[RoleRouter] startup initialRoute=$route');

      final needsBiometric = route != LoginScreen.routeName &&
          route != OnboardingScreen.routeName &&
          await BiometricService.shouldPromptOnLaunch;

      if (!mounted) return;
      if (needsBiometric) {
        nav.pushReplacementNamed(BiometricLockScreen.routeName,
            arguments: route);
        return;
      }
      nav.pushReplacementNamed(route);
    } on SessionExpiredException catch (e) {
      debugPrint('[RoleRouter] startup session expired: $e');
      RoleRouter.setLastError(e.message);
      await NotificationService.onLogout();
      await ApiService.logout();
      if (!mounted) return;
      nav.pushReplacementNamed(LoginScreen.routeName);
    } catch (e) {
      debugPrint('[RoleRouter] startup error: $e');
      RoleRouter.setLastError(e.toString());
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'No pudimos verificar tu sesión. Revisá tu conexión e intentá de nuevo.';
        _retrying = false;
      });
    } finally {
      if (mounted && _errorMessage == null) {
        setState(() => _retrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppErrorState(
                title: 'Problema al iniciar',
                message: _errorMessage,
                retryLabel: 'Reintentar',
                onRetry: _retrying ? null : () => unawaited(_go()),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _InvalidPaymentRouteScreen extends StatelessWidget {
  const _InvalidPaymentRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title:
            Text('Pago', style: AppTextStyles.heading.copyWith(fontSize: 18)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: AppErrorState(
          title: 'No pudimos abrir el pago',
          message: 'Volvé a Mis reservas o a la clase y tocá completar pago.',
          retryLabel: 'Volver',
          onRetry: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}
