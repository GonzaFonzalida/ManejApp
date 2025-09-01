import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manejapp/screens/login_screen.dart';
import 'package:manejapp/screens/register_screen.dart';
import 'package:manejapp/screens/ChooseRoleScreen.dart';
import 'package:manejapp/screens/home_screen.dart';
import 'package:manejapp/screens/editarPerfil_screen.dart'; // 👈 importa la pantalla de editar perfil
import 'package:manejapp/screens/profile_screen.dart';
import 'package:manejapp/screens/ReservarClase_Screen.dart';
import 'package:manejapp/services/api_service.dart';

void main() {
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
    final storage = FlutterSecureStorage();
    final isValid = await ApiService.isSessionValid();
    final hasToken = await storage.read(key: 'auth_token') != null;

    if (isValid && hasToken) {
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
      initialRoute: _initialRoute ?? LoginScreen.routeName,
      routes: {
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
        EditarPerfilScreen.routeName: (context) => const EditarPerfilScreen(), // 👈 añadida
        ReservarClaseScreen.routeName: (context) => const ReservarClaseScreen(),
        ProfileScreen.routeName: (context) => const ProfileScreen(),
      },
    );
  }
}
