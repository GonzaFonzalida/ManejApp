import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

// Este es un servicio de autenticación ficticio para simular la obtención del token.
// En tu aplicación real, esta clase contendría la lógica para obtener el token
// de un lugar seguro (por ejemplo, desde SharedPreferences o Flutter Secure Storage)
// después del inicio de sesión.
class AuthService {
  static Future<String> getToken() async {
    // Simula una llamada asíncrona para obtener el token.
    // Reemplaza esto con tu lógica real de obtención de token.
    return 'fake-auth-token-12345';
  }
  static Future<int> getUserId() async {
    // Simula una llamada asíncrona para obtener el ID de usuario.
    // Reemplaza esto con tu lógica real de obtención de ID.
    return 98765; 
  }
}

// El widget de la pantalla de selección de rol ya no necesita el token y userId
// como parámetros requeridos.
class ChooseRoleScreen extends StatefulWidget {
  static const routeName = 'choose-role';
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String _selectedRole = 'STUDENT';
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  bool _isLoading = false;

  // Nuevos estados para almacenar el token y el userId una vez que se obtienen.
  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    // Inicia la carga del token y el userId apenas se crea el widget.
    _loadAuthData();
  }

  // Método asíncrono para obtener el token y el userId del servicio de autenticación.
  Future<void> _loadAuthData() async {
    setState(() => _isLoading = true);
    try {
      _token = await AuthService.getToken();
      _userId = await AuthService.getUserId();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de autenticación: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  // El método de envío ahora utiliza las variables de estado _token y _userId.
  Future<void> _submitRole() async {
    // Verificamos si los datos de autenticación ya han sido cargados.
    if (_token == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando datos de autenticación, por favor espere.')),
      );
      return;
    }

    if (_selectedRole == 'INSTRUCTOR' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == 'INSTRUCTOR') {
        // Usamos _token! y _userId! para indicar que no son nulos en este punto.
        await ApiService.updateRole(_token!, _userId!, _selectedRole);
        await ApiService.createInstructor(
          _token!,
          _userId!,
          _licenseNumberController.text,
          int.parse(_experienceYearsController.text),
        );
      } else {
        await ApiService.updateRole(_token!, _userId!, _selectedRole);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tu rol ha sido actualizado a ${_selectedRole.toLowerCase()}.')),
      );

      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si la pantalla está cargando el token, muestra un indicador.
    if (_token == null && _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // El resto del código `build` es el mismo que antes, pero usa las variables de estado.
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const Text('Completa tu perfil', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 8),
                const Text('Elige tu rol', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                const Text('Selecciona el rol que mejor te describa. Esto nos ayudará a personalizar tu experiencia.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 40),

                // Botón de Instructor
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRole = 'INSTRUCTOR';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedRole == 'INSTRUCTOR' ? const Color(0xFFE3F2FD) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedRole == 'INSTRUCTOR' ? const Color(0xFF2196F3) : Colors.black12, width: 2),
                      boxShadow: [ if (_selectedRole == 'INSTRUCTOR') BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, spreadRadius: 2) ],
                    ),
                    child: Row(children: [ const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.school, color: Color(0xFF2196F3))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [ Text('Instructor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Comparte tu experiencia y gana enseñando a otros.', style: TextStyle(fontSize: 14, color: Colors.black54))]))])
                  ),
                ),
                const SizedBox(height: 16),

                // Botón de Estudiante
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRole = 'STUDENT';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedRole == 'STUDENT' ? const Color(0xFFE3F2FD) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _selectedRole == 'STUDENT' ? const Color(0xFF2196F3) : Colors.black12, width: 2),
                      boxShadow: [ if (_selectedRole == 'STUDENT') BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, spreadRadius: 2) ],
                    ),
                    child: Row(children: [ const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.person, color: Color(0xFF2196F3))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [ Text('Estudiante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('Aprende nuevas habilidades y expande tus conocimientos con instructores expertos.', style: TextStyle(fontSize: 14, color: Colors.black54))]))])
                  ),
                ),

                const SizedBox(height: 24),

                // Campos adicionales para Instructor que se muestran condicionalmente.
                if (_selectedRole == 'INSTRUCTOR')
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _licenseNumberController,
                          decoration: const InputDecoration(labelText: 'Número de Licencia', prefixIcon: Icon(Icons.credit_card), border: OutlineInputBorder()),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese el número de licencia';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _experienceYearsController,
                          decoration: const InputDecoration(labelText: 'Años de Experiencia', prefixIcon: Icon(Icons.emoji_events), border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) { return 'Por favor, ingrese los años de experiencia'; }
                            if (int.tryParse(value) == null) { return 'Ingrese un número válido'; }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // Botón Continuar, que ahora muestra un indicador de carga.
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitRole,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Continuar', style: TextStyle(fontSize: 18))
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
