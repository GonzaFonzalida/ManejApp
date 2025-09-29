import 'package:flutter/material.dart';
import '../controllers/EditarPerfil_Controller.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class EditarPerfilScreen extends StatefulWidget {
  static var routeName = '/editarPerfil';
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final EditarPerfilController controller = EditarPerfilController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      final profile = await ApiService.getUserProfile(userId);
      controller.nombreController.text = profile['name'] ?? '';
      controller.descripcionController.text = profile['description'] ?? '';
      controller.zonaController.text = profile['zone'] ?? '';
      controller.precioController.text = profile['hourlyRate']?.toString() ?? '';
      controller.disponibilidadController.text = profile['availability'] ?? '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        await ApiService.updateProfile(userId, {
          'name': controller.nombreController.text,
          'description': controller.descripcionController.text,
          'zone': controller.zonaController.text,
          'hourlyRate': int.tryParse(controller.precioController.text) ?? 0,
          'availability': controller.disponibilidadController.text,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil guardado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar perfil: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Editar Perfil",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text(
              "Guardar",
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundImage: AssetImage("assets/car3.png"),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildInputCard(
              child: TextField(
                controller: controller.nombreController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  labelText: "Nombre Completo",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              child: TextField(
                controller: controller.descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.edit_outlined),
                  labelText: "Descripción",
                  hintText: "Contá un poco sobre vos...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              child: TextField(
                controller: controller.zonaController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                  labelText: "Zona donde vive",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              child: TextField(
                controller: controller.precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money_outlined),
                  labelText: "Precio por hora",
                  prefixText: "\$ ",
                  suffixText: "/h",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInputCard(
              child: TextField(
                controller: controller.disponibilidadController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time),
                  labelText: "Disponibilidad",
                  hintText: "Ej: Lunes a Sábado, 9:00 - 19:00",
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: child,
      ),
    );
  }
}