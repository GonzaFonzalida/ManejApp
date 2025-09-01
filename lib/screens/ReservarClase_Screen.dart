import 'package:flutter/material.dart';
import '../controllers/ReservarClase_Controller.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/instructor.dart';

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

  Future<void> _reserveClass(String instructorId) async {
    setState(() => _isLoading = true);
    try {
      final date = controller.fechas[controller.fechaSeleccionada.value];
      final time = controller.horaSeleccionada.value;
      await ApiService.reserveClass(instructorId, {
        'date': date,
        'time': time,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clase reservada')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reservar clase: $e')),
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
              backgroundImage: AssetImage(instructor?.image ?? "assets/car1.png"),
            ),
            const SizedBox(height: 12),
            Text(
              instructor?.name ?? "Instructor",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Soy un instructor paciente y profesional con 10 años de experiencia...",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Column(
                  children: [
                    Text("Precio"),
                    Text("\$45.000/h", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
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
                    onPressed: instructor != null ? () => _reserveClass(instructor.id.toString()) : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Reservar Clase"),
                  ),
          ],
        ),
      ),
    );
  }
}