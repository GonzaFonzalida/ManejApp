import 'package:flutter/material.dart';
import 'package:manejapp/screens/ChooseRoleScreen.dart';
import 'package:manejapp/screens/EditarPerfil_Screen.dart';
import 'package:manejapp/screens/ReservarClase_Screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart'; // Importamos la pantalla de inicio

void main() {
  runApp(const ManejApp());
}

class ManejApp extends StatelessWidget {
  const ManejApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ManejApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(), // ¡Ruta de HomeScreen agregada!
        ChooseRoleScreen.routeName: (context) => const ChooseRoleScreen(),
        ReservarClaseScreen.routeName: (context) => ReservarClaseScreen(),
        EditarPerfilScreen.routeName: (context) => EditarPerfilScreen(),
      },
    );
  }
}
