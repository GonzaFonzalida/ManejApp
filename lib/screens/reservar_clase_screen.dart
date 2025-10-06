import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/instructor.dart';
import '../models/schedule_slot.dart';
import 'payment_screen.dart';
import 'package:intl/intl.dart';


const storage = FlutterSecureStorage();

class ReservarClaseScreen extends StatefulWidget {
  static const routeName = '/reservarClase';
  const ReservarClaseScreen({super.key});

  @override
  State<ReservarClaseScreen> createState() => _ReservarClaseScreenState();
}

class _ReservarClaseScreenState extends State<ReservarClaseScreen> {
  List<ScheduleSlot> _availableSlots = [];
  ScheduleSlot? _selectedSlot;
  bool _isLoading = true;
  String? _instructorId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadAvailableSlots();
    }
  }

  Future<void> _loadAvailableSlots() async {
    final instructor = ModalRoute.of(context)?.settings.arguments as Instructor?;
    if (instructor != null) {
      _instructorId = instructor.id.toString();
      try {
        final slots = await ApiService.getInstructorSchedule(_instructorId!);
        debugPrint('Slots obtenidos para instructor $_instructorId: ${slots.length}');
        
        for (var slot in slots) {
          debugPrint('Slot: ${slot['id']}, isBooked: ${slot['isBooked']}');
        }
        
        _availableSlots = slots
            .where((s) => s['isBooked'] != true) // Backend usa isBooked, no isAvailable
            .map((s) => ScheduleSlot.fromJson(s))
            .toList();
            
        debugPrint('Horarios disponibles para reservar: ${_availableSlots.length}');
        
        // Filtrar solo slots futuros
        final now = DateTime.now();
        _availableSlots = _availableSlots
            .where((slot) => slot.date.isAfter(now.subtract(const Duration(hours: 1))))
            .toList();
        
        // Ordenar por fecha
        _availableSlots.sort((a, b) => a.date.compareTo(b.date));
      } catch (e) {
        debugPrint('Error cargando horarios: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cargando horarios: $e')),
          );
        }
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reserveSlot(Instructor instructor) async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un horario')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Validate slot ID
      final slotId = _selectedSlot!.id;
      print('DEBUG: Slot ID: $slotId (type: ${slotId.runtimeType})');
      
      if (slotId == null) {
        throw Exception('ID del slot es null');
      }
      
      final slotIdString = slotId.toString();
      print('DEBUG: Slot ID string: "$slotIdString"');
      
      if (slotIdString.isEmpty || slotIdString == 'null') {
        throw Exception('ID del slot no válido: $slotIdString');
      }
      
      // 1. Reservar el slot (esto ya crea la clase automáticamente)
      final reservationResult = await ApiService.reserveScheduleSlot(slotIdString);
      final classId = reservationResult['drivingClass']['id'];
      
      print('DEBUG: Class ID from reservation: $classId');
      
      // 3. Crear preferencia de pago
      final response = await ApiService.mpCreatePreference(
        drivingClassId: classId,
        amount: 1, // Precio de prueba
        description: 'Clase con ${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''} el ${DateFormat('dd/MM/yyyy').format(_selectedSlot!.date)} a las ${_selectedSlot!.startTime}',
        payerEmail: await storage.read(key: 'user_email'),
      );
      
      if (!mounted) return;
      
      // 4. Navegar a pantalla de pago
      Navigator.pushNamed(
        context,
        PaymentScreen.routeName,
        arguments: {
          'preferenceId': response['id'],
          'drivingClassId': classId,
          'amount': 1, // Precio de prueba
          'description': 'Clase con ${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}',
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reservar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructor = ModalRoute.of(context)?.settings.arguments as Instructor?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservar Clase"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Información del instructor
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: instructor?.image != null && instructor!.image!.startsWith('http')
                        ? NetworkImage(instructor.image!) as ImageProvider
                        : const AssetImage("assets/car3.png"),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${instructor?.user?.name ?? ''} ${instructor?.user?.surname ?? ''}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${instructor?.experienceYears ?? 0} años de experiencia',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text("Precio"),
                          Text(
                            "\$${instructor?.user?.hourlyRate?.toStringAsFixed(0) ?? '45.000'}/h",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text("Calificación"),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(
                                '${instructor?.rating ?? '5.0'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Horarios disponibles
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Horarios Disponibles",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: _availableSlots.isEmpty
                        ? const Center(
                            child: Text(
                              'Este instructor no tiene horarios disponibles en este momento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _availableSlots[index];
                              final isSelected = _selectedSlot?.id == slot.id;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  selected: isSelected,
                                  selectedTileColor: const Color(0xFF003087).withValues(alpha: 0.1),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected 
                                        ? const Color(0xFF003087)
                                        : Colors.grey.shade300,
                                    child: Icon(
                                      Icons.schedule,
                                      color: isSelected ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                  title: Text(
                                    DateFormat('EEEE, d MMMM yyyy').format(slot.date),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('${slot.startTime} - ${slot.endTime}'),
                                  trailing: isSelected 
                                      ? const Icon(Icons.check_circle, color: Color(0xFF003087))
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedSlot = isSelected ? null : slot;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: instructor != null && _selectedSlot != null
                          ? () => _reserveSlot(instructor)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003087),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Reservar y Pagar",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}