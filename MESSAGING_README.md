# 📱 Módulo de Mensajería - ManejApp

## ✅ Implementación Completa

Se ha implementado el módulo completo de mensajería para consumir los endpoints del backend.

## 📦 Instalación

1. **Instalar dependencias:**
```bash
flutter pub get
```

2. **Verificar que el backend esté corriendo** en la URL configurada en `ConfigService`

## 🗂️ Archivos Creados/Modificados

### Nuevos Archivos
```
lib/
├── models/
│   └── message.dart                    # Modelos de mensajes y conversaciones
├── controllers/
│   └── chat_controller.dart            # Controlador de estado
├── screens/
│   └── conversations_screen.dart       # Lista de conversaciones
└── widgets/
    └── message_badge.dart              # Badge de mensajes no leídos
```

### Archivos Modificados
```
lib/
├── services/
│   └── api_service.dart                # +5 métodos de mensajería
├── screens/
│   └── chat_screen.dart                # Integración con backend
├── main.dart                           # Provider y rutas
└── pubspec.yaml                        # +provider dependency
```

## 🚀 Uso Rápido

### 1. Ver todas las conversaciones
```dart
Navigator.pushNamed(context, ConversationsScreen.routeName);
```

### 2. Iniciar chat con un usuario
```dart
Navigator.pushNamed(
  context,
  ChatScreen.routeName,
  arguments: {
    'recipientName': 'Nombre del Usuario',
    'recipientId': '123',
    'conversationId': null, // null = nueva conversación
  },
);
```

### 3. Agregar botón de mensajes con badge
```dart
import 'package:manejapp/widgets/message_badge.dart';

MessageBadge(
  child: IconButton(
    icon: const Icon(Icons.message),
    onPressed: () {
      Navigator.pushNamed(context, ConversationsScreen.routeName);
    },
  ),
)
```

## 🎯 Características

✅ **Envío de mensajes** - Validación 1-1000 caracteres
✅ **Lista de conversaciones** - Con último mensaje y fecha
✅ **Chat en tiempo real** - Historial completo de mensajes
✅ **Marcado como leído** - Automático al abrir conversación
✅ **Contador de no leídos** - Badge con número de mensajes
✅ **Indicadores de estado** - ✓ enviado, ✓✓ leído
✅ **Auto-scroll** - Al enviar/recibir mensajes
✅ **Pull-to-refresh** - Actualizar conversaciones
✅ **Manejo de errores** - Mensajes informativos

## 🔌 Endpoints Integrados

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | `/api/v1/messages/send` | Enviar mensaje |
| GET | `/api/v1/messages/conversations` | Listar conversaciones |
| GET | `/api/v1/messages/conversations/:id/messages` | Mensajes de conversación |
| GET | `/api/v1/messages/unread-count` | Contador de no leídos |
| PUT | `/api/v1/messages/conversations/:id/read` | Marcar como leído |

## 📖 Ejemplos de Integración

### Ejemplo 1: Botón "Contactar Instructor"
```dart
ElevatedButton.icon(
  icon: const Icon(Icons.message),
  label: const Text('Contactar'),
  onPressed: () {
    Navigator.pushNamed(
      context,
      ChatScreen.routeName,
      arguments: {
        'recipientName': instructor.fullName,
        'recipientId': instructor.userId.toString(),
        'conversationId': null,
      },
    );
  },
)
```

### Ejemplo 2: Badge en AppBar
```dart
import 'package:provider/provider.dart';
import 'package:manejapp/controllers/chat_controller.dart';
import 'package:manejapp/widgets/message_badge.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar contador al iniciar
    Future.microtask(() {
      context.read<ChatController>().loadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
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
      body: // ...
    );
  }
}
```

### Ejemplo 3: Actualizar contador después de enviar mensaje
```dart
// Después de enviar un mensaje
await context.read<ChatController>().sendMessage(receiverId, content);
await context.read<ChatController>().loadUnreadCount();
```

## 🔧 Configuración

El módulo usa la configuración existente de `ConfigService` para la URL base del API.

```dart
// En config_service.dart
static String get baseUrl => _config['baseUrl'] ?? 'http://localhost:3000';
```

## 📝 Notas Importantes

- **Autenticación requerida**: Todos los endpoints requieren JWT token
- **Auto-creación**: Las conversaciones se crean automáticamente si no existen
- **Ordenamiento**: Los participantes se ordenan por ID para evitar duplicados
- **Validación**: El contenido debe tener entre 1 y 1000 caracteres
- **Marcado automático**: Los mensajes se marcan como leídos al abrir la conversación

## 🐛 Troubleshooting

### Error: "No autenticado"
- Verificar que el usuario haya iniciado sesión
- Verificar que el token JWT sea válido

### Error: "Error obteniendo conversaciones"
- Verificar que el backend esté corriendo
- Verificar la URL en ConfigService
- Verificar logs del backend

### Los mensajes no se actualizan
- Usar pull-to-refresh en la lista de conversaciones
- Verificar conexión a internet

## 📚 Documentación Adicional

Ver `docs/MESSAGING_INTEGRATION.md` para más detalles técnicos y ejemplos avanzados.

## 🎨 Personalización

### Cambiar colores del chat
```dart
// En chat_screen.dart, línea ~180
color: isSent ? const Color(0xFF003087) : Colors.grey.shade200,
```

### Cambiar formato de fecha
```dart
// En conversations_screen.dart, línea ~85
DateFormat('dd/MM HH:mm').format(conv.lastMessage!.sentAt)
```

## ✨ Próximas Mejoras (Opcionales)

- [ ] WebSocket para mensajes en tiempo real
- [ ] Notificaciones push para nuevos mensajes
- [ ] Envío de imágenes/archivos
- [ ] Mensajes de voz
- [ ] Indicador "escribiendo..."
- [ ] Búsqueda de mensajes
- [ ] Eliminar conversaciones
- [ ] Bloquear usuarios

---

**Desarrollado para ManejApp** 🚗
