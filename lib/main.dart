import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manejapp/screens/login_screen.dart';
import 'package:manejapp/screens/payment_screen.dart';
import 'package:manejapp/screens/register_screen.dart';
import 'package:manejapp/screens/choose_role_screen.dart';
import 'package:manejapp/screens/home_screen.dart';
import 'package:manejapp/screens/editar_perfil_screen.dart';
import 'package:manejapp/screens/profile_screen.dart';
import 'package:manejapp/screens/reservar_clase_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/screens/map_screen.dart';
import 'package:manejapp/screens/instructor_dashboard_screen.dart';
import 'package:manejapp/screens/student_dashboard_screen.dart';
import 'package:manejapp/screens/student_classes_screen.dart';
import 'package:manejapp/screens/student_payments_screen.dart';
import 'package:manejapp/screens/admin_dashboard_screen.dart';
import 'package:manejapp/screens/settings_screen.dart';
import 'package:manejapp/screens/chat_screen.dart';
import 'package:manejapp/screens/onboarding_screen.dart';
import 'package:manejapp/services/notification_service.dart';
import 'package:manejapp/services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.loadConfig();
  await NotificationService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    const storage = FlutterSecureStorage();
    
    // Verificar si es la primera vez
    final onboardingCompleted = await storage.read(key: 'onboarding_completed');
    if (onboardingCompleted != 'true') {
      setState(() {
        _initialRoute = OnboardingScreen.routeName;
      });
      return;
    }
    
    final isValid = await ApiService.isSessionValid();
    final hasToken = await storage.read(key: 'auth_token') != null;

    if (isValid && hasToken) {
      // Verificar el rol del usuario
      try {
        final userId = await storage.read(key: 'user_id');
        if (userId != null) {
          final profile = await ApiService.getUserProfile(userId);
          final role = profile['role'] as String?;
          
          if (role == 'ADMIN') {
            setState(() {
              _initialRoute = AdminDashboardScreen.routeName;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Error verificando rol: $e');
      }
      
      setState(() {
        _initialRoute = HomeScreen.routeName;
      });
    } else {
      // Limpiar datos de sesión inválidos
      await ApiService.logout();
      setState(() {
        _initialRoute = LoginScreen.routeName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ManejApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003087)),
        useMaterial3: true,
      ),
      initialRoute: _initialRoute ?? OnboardingScreen.routeName,
      routes: {
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        '/choose_role': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is String && arguments.isNotEmpty) {
            return ChooseRoleScreen(userId: arguments);
          }
          return const LoginScreen();
        },
        HomeScreen.routeName: (context) => const HomeScreen(),
        EditarPerfilScreen.routeName: (context) => const EditarPerfilScreen(),
        ReservarClaseScreen.routeName: (context) => const ReservarClaseScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
        MapScreen.routeName: (context) => const MapScreen(),
        PaymentScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            return PaymentScreen(
              drivingClassId: arguments['drivingClassId'] as int,
              amount: arguments['amount'] as int,
              description: arguments['description'] as String,
              payerEmail: arguments['payerEmail'] as String?,
            );
          }
          // Fallback with dummy values if no arguments provided
          return const PaymentScreen(
            drivingClassId: 0,
            amount: 0,
            description: 'Sin descripción',
          );
        },
        // Rutas del instructor
        InstructorDashboardScreen.routeName: (context) => const InstructorDashboardScreen(),
        // Rutas del estudiante  
        StudentDashboardScreen.routeName: (context) => const StudentDashboardScreen(),
        '/student_classes': (context) => const StudentClassesScreen(),
        '/student_payments': (context) => const StudentPaymentsScreen(),
        // Rutas del admin
        AdminDashboardScreen.routeName: (context) => const AdminDashboardScreen(),
        // Rutas generales
        SettingsScreen.routeName: (context) => const SettingsScreen(),
        ChatScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            return ChatScreen(
              recipientName: arguments['recipientName'] as String,
              recipientId: arguments['recipientId'] as String,
            );
          }
          return const LoginScreen();
        },
      },
    );
  }
}