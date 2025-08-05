import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Importamos nuestra pantalla de login

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
      home: const LoginScreen(), // Mostramos el login primero
    );
  }
}
