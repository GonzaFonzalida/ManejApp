import 'package:flutter/material.dart';
import '../controllers/EditarPerfil_Controller.dart';

class EditarPerfilScreen extends StatelessWidget {
  final EditarPerfilController controller = EditarPerfilController();

  static var routeName = '/editarPerfil';

  EditarPerfilScreen({super.key});

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
            onPressed: () {
              // futuro guardar en backend
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Perfil guardado")),
              );
            },
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
            // Avatar con botón de cámara
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 55,
                  backgroundImage: AssetImage("assets/avatar_placeholder.png"),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
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

            // Campos de texto en Cards
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
