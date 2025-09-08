import 'package:flutter/material.dart';
import '../controllers/ReservarClase_Controller.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/instructor.dart';
import 'payment_screen.dart';
import 'dart:developer' as developer;

const storage = FlutterSecureStorage();

class ReservarClaseScreen extends StatefulWidget {
  static var routeName = '/reservarClase';
  const ReservarClaseScreen({super.key});

  @override
  State<ReservarClaseScreen> createState() => _ReservarClaseScreenState();
}

class _ReservarClaseScreenState extends State<ReservarClaseScreen> {
  final ReservarClaseController controller = ReservarClaseController();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _reserveClass(Instructor instructor) async {
    setState(() => _isLoading = true);
    try {
      final date = controller.fechas[controller.fechaSeleccionada.value];
      final time = controller.horaSeleccionada.value;

      // ✅ CORRECCIÓN: Leer el ID del estudiante desde el almacenamiento seguro
      final studentId = await storage.read(key: 'user_id');
      if (studentId == null) {
        throw Exception('El ID del estudiante no está disponible. Por favor, vuelva a iniciar sesión.');
      }

      // Paso 1: Llamar al backend para reservar la clase
      final response = await ApiService.reserveClass(
        instructor.id.toString(), {
          'date': date,
          'time': time,
          'studentId': int.parse(studentId), // ✅ CORRECCIÓN: Se envía el ID del estudiante
        },
      );

      // ✅ Muestra la respuesta del servidor en la consola para depurar
      developer.log('Respuesta del servidor: $response', name: 'ReservarClaseScreen');

      if (!mounted) return;

      // Paso 2: Obtener el ID de la clase de la respuesta y validar
      final drivingClassId = response['id'];
      if (drivingClassId == null) {
        throw Exception('El ID de la clase no se recibió correctamente en la respuesta del servidor.');
      }
      
      // Paso 3: Leer el email del storage para el pago
      final userEmail = await storage.read(key: 'user_email');
      
      // Paso 4: Navegar a la pantalla de pago con los datos necesarios
      Navigator.pushNamed(
        context,
        PaymentScreen.routeName,
        arguments: {
          'drivingClassId': drivingClassId,
          'amount': 45000,
          // ✅ CORRECCIÓN: Accede al nombre a través del objeto 'user'
          'description': 'Clase con ${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''} el $date a las $time',
          'payerEmail': userEmail,
        },
      );
    } catch (e, stacktrace) {
      if (!mounted) return;
      // ✅ Ahora la SnackBar muestra el error completo y el stacktrace para depurar mejor
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reservar clase: ${e.toString()}\nStacktrace: ${stacktrace.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructor = ModalRoute.of(context)?.settings.arguments as Instructor?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ManejApp"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              // ✅ CORRECCIÓN: Ahora se verifica la URL de la imagen.
              backgroundImage: instructor?.image != null && instructor!.image!.startsWith('http')
                  ? NetworkImage(instructor.image!) as ImageProvider
                  : const AssetImage("assets/default_profile.png"),
            ),
            const SizedBox(height: 12),
            Text(
              // ✅ CORRECCIÓN: Accede al nombre a través del objeto 'user'
              '${instructor?.user?.name ?? ''} ${instructor?.user?.surname ?? ''}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Soy un instructor paciente y profesional con 10 años de experiencia...",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Column(
                  children: [
                    Text("Precio"),
                    Text("\$70.000/h", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const Column(
                  children: [
                    Text("Zona"),
                    Text("Tortuguitas", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Elegir Fecha", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: controller.fechas.length,
                itemBuilder: (context, index) {
                  return ValueListenableBuilder<int>(
                    valueListenable: controller.fechaSeleccionada,
                    builder: (context, selected, _) {
                      bool isSelected = selected == index;
                      return GestureDetector(
                        onTap: () => controller.seleccionarFecha(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(controller.fechas[index],
                              style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text("Horarios Disponibles", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: controller.horarios.map((hora) {
                return ValueListenableBuilder<String?>(
                  valueListenable: controller.horaSeleccionada,
                  builder: (context, selected, _) {
                    bool isSelected = selected == hora;
                    return ChoiceChip(
                      label: Text(hora),
                      selected: isSelected,
                      onSelected: (_) => controller.seleccionarHora(hora),
                      selectedColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: instructor != null
                        ? () => _reserveClass(instructor)
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Reservar y Pagar"),
                  ),
          ],
        ),
      ),
    );
  }
}