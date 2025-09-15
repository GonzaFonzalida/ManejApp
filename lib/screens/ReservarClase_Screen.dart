import 'package:flutter/material.dart';
import '../controllers/ReservarClase_Controller.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/instructor.dart';
import 'payment_screen.dart';
import 'dart:developer' as developer;

const storage = FlutterSecureStorage();

class ReservarClaseScreen extends StatefulWidget {
  static const routeName = '/reservarClase';
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
      final String dateDisplay = controller.selectedDisplayDate;
      final String? time = controller.horaSeleccionada.value;

      if (time == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccione un horario')),
        );
        return;
      }

      // ✅ CAMBIO CLAVE: Llamada directa a Mercado Pago para crear una preferencia
      // Se utiliza un ID de clase temporal (12345) ya que aún no se ha creado en el backend.
      // El precio es fijo en $45.000 (debes ajustar si es necesario).
      final response = await ApiService.mpCreatePreference(
        drivingClassId: 12345, // ID de prueba, cambiará en producción
        amount: 45000,
        description: 'Clase con ${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''} el $dateDisplay a las $time',
        payerEmail: await storage.read(key: 'user_email'),
      );
      
      developer.log('Respuesta de Mercado Pago: $response', name: 'ReservarClaseScreen');

      if (!mounted) return;

      final preferenceId = response['id'];
      if (preferenceId == null) {
        throw Exception('El ID de la preferencia no se recibió correctamente en la respuesta de Mercado Pago.');
      }
      
      // ✅ Navegar a la pantalla de pago con el ID de la preferencia
      Navigator.pushNamed(
        context,
        PaymentScreen.routeName,
        arguments: {
          'preferenceId': preferenceId,
          'drivingClassId': 12345,
          'amount': 45000,
          'description': 'Clase con ${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''} el $dateDisplay a las $time',
        },
      );
    } catch (e, stacktrace) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear preferencia de pago: ${e.toString()}\nStacktrace: ${stacktrace.toString()}'),
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
              backgroundImage: instructor?.image != null && instructor!.image!.startsWith('http')
                  ? NetworkImage(instructor.image!) as ImageProvider
                  : const AssetImage("assets/default_profile.png"),
            ),
            const SizedBox(height: 12),
            Text(
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
                itemCount: controller.displayFechas.length,
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
                          child: Text(controller.displayFechas[index],
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