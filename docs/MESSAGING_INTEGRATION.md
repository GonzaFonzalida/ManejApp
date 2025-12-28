# Integración del Módulo de Mensajería

## Archivos Creados

### Modelos
- `lib/models/message.dart` - Modelos de Message, MessageSender y Conversation

### Controladores
- `lib/controllers/chat_controller.dart` - Gestión de estado de mensajería

### Pantallas
- `lib/screens/conversations_screen.dart` - Lista de conversaciones
- `lib/screens/chat_screen.dart` - Chat individual (actualizado)

### Widgets
- `lib/widgets/message_badge.dart` - Badge con contador de mensajes no leídos

### Servicios
- `lib/services/api_service.dart` - Métodos API agregados:
  - `sendMessage(receiverId, content)`
  - `getConversations()`
  - `getConversationMessages(conversationId)`
  - `getUnreadMessagesCount()`
  - `markConversationAsRead(conversationId)`

## Uso Básico

### 1. Navegar a la lista de conversaciones

```dart
Navigator.pushNamed(context, ConversationsScreen.routeName);
```

### 2. Iniciar un chat con un usuario específico

```dart
Navigator.pushNamed(
  context,
  ChatScreen.routeName,
  arguments: {
    'recipientName': 'Juan Pérez',
    'recipientId': '123',
    'conversationId': null, // null para nueva conversación
  },
);
```

### 3. Abrir una conversación existente

```dart
Navigator.pushNamed(
  context,
  ChatScreen.routeName,
  arguments: {
    'recipientName': 'Juan Pérez',
    'recipientId': '123',
    'conversationId': 456, // ID de conversación existente
  },
);
```

### 4. Mostrar badge con mensajes no leídos

```dart
import 'package:manejapp/widgets/message_badge.dart';

// En tu AppBar o botón
MessageBadge(
  child: IconButton(
    icon: const Icon(Icons.message),
    onPressed: () {
      Navigator.pushNamed(context, ConversationsScreen.routeName);
    },
  ),
)
```

### 5. Cargar contador de mensajes no leídos

```dart
import 'package:provider/provider.dart';
import 'package:manejapp/controllers/chat_controller.dart';

// En initState o cuando necesites actualizar
await context.read<ChatController>().loadUnreadCount();
```

## Ejemplo de Integración en HomeScreen

```dart
import 'package:manejapp/widgets/message_badge.dart';
import 'package:manejapp/screens/conversations_screen.dart';
import 'package:manejapp/controllers/chat_controller.dart';

class HomeScreen extends StatefulWidget {
  // ...
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: const Text('ManejApp'),
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
      // ... resto del código
    );
  }
}
```

## Ejemplo: Botón "Contactar Instructor"

```dart
// En la pantalla de detalles del instructor
ElevatedButton.icon(
  icon: const Icon(Icons.message),
  label: const Text('Contactar'),
  onPressed: () {
    Navigator.pushNamed(
      context,
      ChatScreen.routeName,
      arguments: {
        'recipientName': instructor.name,
        'recipientId': instructor.userId.toString(),
        'conversationId': null,
      },
    );
  },
)
```

## Características Implementadas

✅ Envío de mensajes (1-1000 caracteres)
✅ Lista de conversaciones con último mensaje
✅ Vista de chat con historial completo
✅ Marcado automático como leído al abrir conversación
✅ Contador de mensajes no leídos
✅ Indicadores de mensaje enviado/leído (✓/✓✓)
✅ Auto-creación de conversaciones
✅ Scroll automático a último mensaje
✅ Pull-to-refresh en conversaciones
✅ Estados de carga y errores

## Notas Importantes

- El backend crea automáticamente conversaciones si no existen
- Los mensajes se marcan como leídos al cargar la conversación
- El contador de no leídos solo cuenta mensajes donde el usuario NO es el remitente
- Los participantes se ordenan por ID para evitar duplicados
- Validación de contenido: 1-1000 caracteres
- Requiere autenticación JWT en todos los endpoints

## Endpoints Backend Utilizados

- `POST /api/v1/messages/send`
- `GET /api/v1/messages/conversations`
- `GET /api/v1/messages/conversations/:id/messages`
- `GET /api/v1/messages/unread-count`
- `PUT /api/v1/messages/conversations/:id/read`
