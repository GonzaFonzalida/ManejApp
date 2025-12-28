// EJEMPLO DE INTEGRACIÓN DEL MÓDULO DE MENSAJERÍA
// Este archivo muestra cómo integrar el módulo en tus pantallas existentes

// ============================================================================
// EJEMPLO 1: Agregar botón de mensajes en HomeScreen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manejapp/controllers/chat_controller.dart';
import 'package:manejapp/widgets/message_badge.dart';
import 'package:manejapp/screens/conversations_screen.dart';

class HomeScreenExample extends StatefulWidget {
  const HomeScreenExample({super.key});

  @override
  State<HomeScreenExample> createState() => _HomeScreenExampleState();
}

class _HomeScreenExampleState extends State<HomeScreenExample> {
  @override
  void initState() {
    super.initState();
    // Cargar contador de mensajes no leídos al iniciar
    Future.microtask(() {
      context.read<ChatController>().loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ManejApp'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        actions: [
          // Badge con contador de mensajes no leídos
          MessageBadge(
            child: IconButton(
              icon: const Icon(Icons.message),
              tooltip: 'Mensajes',
              onPressed: () {
                Navigator.pushNamed(context, ConversationsScreen.routeName);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Text('Contenido de tu pantalla'),
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 2: Botón "Contactar Instructor" en lista de instructores
// ============================================================================

class InstructorListItemExample extends StatelessWidget {
  final Map<String, dynamic> instructor;

  const InstructorListItemExample({
    super.key,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(instructor['name'][0]),
        ),
        title: Text('${instructor['name']} ${instructor['surname']}'),
        subtitle: Text('${instructor['experienceYears']} años de experiencia'),
        trailing: IconButton(
          icon: const Icon(Icons.message),
          color: const Color(0xFF003087),
          onPressed: () {
            // Navegar al chat con el instructor
            Navigator.pushNamed(
              context,
              '/chat',
              arguments: {
                'recipientName': '${instructor['name']} ${instructor['surname']}',
                'recipientId': instructor['userId'].toString(),
                'conversationId': null, // null para nueva conversación
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 3: Pantalla de perfil de instructor con botón de contacto
// ============================================================================

class InstructorProfileExample extends StatelessWidget {
  final Map<String, dynamic> instructor;

  const InstructorProfileExample({
    super.key,
    required this.instructor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${instructor['name']} ${instructor['surname']}'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del instructor
            Text(
              'Licencia: ${instructor['licenseNumber']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Experiencia: ${instructor['experienceYears']} años',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Botón para contactar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.message),
                label: const Text('Contactar Instructor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003087),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'recipientName': '${instructor['name']} ${instructor['surname']}',
                      'recipientId': instructor['userId'].toString(),
                      'conversationId': null,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 4: Actualizar contador después de una acción
// ============================================================================

class MessageActionsExample extends StatelessWidget {
  const MessageActionsExample({super.key});

  Future<void> _performActionAndUpdateMessages(BuildContext context) async {
    try {
      // Realizar alguna acción (ej: reservar clase, etc)
      // ...
      
      // Actualizar el contador de mensajes
      await context.read<ChatController>().loadUnreadCount();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acción completada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _performActionAndUpdateMessages(context),
      child: const Text('Realizar Acción'),
    );
  }
}

// ============================================================================
// EJEMPLO 5: Drawer con opción de mensajes
// ============================================================================

class DrawerExample extends StatelessWidget {
  const DrawerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xFF003087),
            ),
            child: Text(
              'ManejApp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          // Opción de mensajes con badge
          Consumer<ChatController>(
            builder: (context, controller, child) {
              return ListTile(
                leading: MessageBadge(
                  child: const Icon(Icons.message),
                ),
                title: const Text('Mensajes'),
                trailing: controller.unreadCount > 0
                    ? Chip(
                        label: Text(
                          controller.unreadCount.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, ConversationsScreen.routeName);
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 6: Botón flotante para mensajes
// ============================================================================

class FloatingMessageButtonExample extends StatelessWidget {
  const FloatingMessageButtonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Pantalla')),
      body: const Center(child: Text('Contenido')),
      floatingActionButton: MessageBadge(
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF003087),
          onPressed: () {
            Navigator.pushNamed(context, ConversationsScreen.routeName);
          },
          child: const Icon(Icons.message, color: Colors.white),
        ),
      ),
    );
  }
}

// ============================================================================
// EJEMPLO 7: Enviar mensaje programáticamente
// ============================================================================

class SendMessageExample extends StatelessWidget {
  const SendMessageExample({super.key});

  Future<void> _sendWelcomeMessage(BuildContext context, int instructorId) async {
    try {
      final chatController = context.read<ChatController>();
      
      // Enviar mensaje de bienvenida
      await chatController.sendMessage(
        instructorId,
        '¡Hola! Me gustaría reservar una clase de manejo.',
      );
      
      // Actualizar contador
      await chatController.loadUnreadCount();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mensaje enviado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _sendWelcomeMessage(context, 123),
      child: const Text('Enviar Mensaje de Bienvenida'),
    );
  }
}

// ============================================================================
// EJEMPLO 8: Verificar mensajes no leídos periódicamente
// ============================================================================

class PeriodicMessageCheckExample extends StatefulWidget {
  const PeriodicMessageCheckExample({super.key});

  @override
  State<PeriodicMessageCheckExample> createState() => _PeriodicMessageCheckExampleState();
}

class _PeriodicMessageCheckExampleState extends State<PeriodicMessageCheckExample> {
  @override
  void initState() {
    super.initState();
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Verificar mensajes cada 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        context.read<ChatController>().loadUnreadCount();
        _startPeriodicCheck(); // Continuar verificando
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación Periódica'),
        actions: [
          MessageBadge(
            child: IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                Navigator.pushNamed(context, ConversationsScreen.routeName);
              },
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text('Los mensajes se verifican cada 30 segundos'),
      ),
    );
  }
}
