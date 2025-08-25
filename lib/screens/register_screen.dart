
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'ChooseRoleScreen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ✅ Importa el paquete de almacenamiento seguro

const storage = FlutterSecureStorage(); // ✅ Instancia para guardar los datos

class RegisterScreen extends StatefulWidget {
  static const routeName = 'register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  String _name = '';
  String _surname = '';
  String _dni = '';
  String _email = '';
  String _password = '';
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // Función para mostrar el selector de fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    // 🔴 Validar el formulario y guardar los campos
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    _name = _name.trim();
    _surname = _surname.trim();
    _email = _email.trim();
    _dni = _dni.trim();

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, seleccione su fecha de nacimiento')),
      );
      return;
    }

    final formattedBirthDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    setState(() => _isLoading = true);
    try {
      // 🟢 CAMBIO PRINCIPAL: Captura el valor de retorno de ApiService.register
      final result = await ApiService.register(
        _name,
        _surname,
        _email,
        _password,
        _dni,
        formattedBirthDate,
      );

      final token = result['token'] as String;
      final userId = result['userId'] as int;

      // ✅ Guarda los datos en el almacenamiento seguro
      await storage.write(key: 'auth_token', value: token);
      await storage.write(key: 'user_id', value: userId.toString());

      // Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );

      // 🟢 Navega a la siguiente pantalla sin pasar argumentos.
      // La pantalla de rol ahora leerá los datos del almacenamiento seguro.
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          ChooseRoleScreen.routeName,
        );
      }
    } catch (e) {
      // Manejo de errores
      String errorMessage = 'Error desconocido. Por favor, intente de nuevo.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en registro: $errorMessage')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Ilustración del auto
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF003087).withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/car3.png',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nombre de la app
                const Text(
                  'ManejApp',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003087),
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 40),
                // Formulario con sombras y bordes redondeados
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Campo de nombre
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese su nombre';
                            }
                            return null;
                          },
                          onSaved: (value) => _name = value!,
                        ),
                        const SizedBox(height: 16),
                        // Nuevo campo para el apellido
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Apellido',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese su apellido';
                            }
                            return null;
                          },
                          onSaved: (value) => _surname = value!,
                        ),
                        const SizedBox(height: 16),
                        // Nuevo campo para el DNI
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'DNI',
                            prefixIcon: const Icon(Icons.credit_card),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese su DNI';
                            }
                            return null;
                          },
                          onSaved: (value) => _dni = value!,
                        ),
                        const SizedBox(height: 16),
                        // Campo de email
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese su correo';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Por favor, ingrese un correo válido';
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value!,
                        ),
                        const SizedBox(height: 16),
                        // Campo de contraseña
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese su contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!,
                        ),
                        const SizedBox(height: 16),
                        // Nuevo campo para la fecha de nacimiento
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          decoration: InputDecoration(
                            labelText: 'Fecha de nacimiento',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (_selectedDate == null) {
                              return 'Por favor, seleccione su fecha de nacimiento';
                            }
                            final now = DateTime.now();
                            final age = now.year - _selectedDate!.year;
                            final isUnderage = age < 18 || (age == 18 && (now.month < _selectedDate!.month || (now.month == _selectedDate!.month && now.day < _selectedDate!.day)));
                            if (isUnderage) {
                              return 'Debe ser mayor de 18 años para registrarse';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Botón Registrarse
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003087),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 12,
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                                child: const Text(
                                  'Registrarse',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                        const SizedBox(height: 16),
                        // Enlace a login
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, LoginScreen.routeName);
                          },
                          child: const Text(
                            '¿Ya tienes cuenta? Inicia sesión',
                            style: TextStyle(
                              color: Color(0xFF003087),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
