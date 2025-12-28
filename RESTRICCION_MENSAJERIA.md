# 🔒 Restricción de Mensajería por Pago

## Cambio Implementado

El módulo de mensajería ahora **requiere que el estudiante tenga un pago confirmado** antes de poder contactar a un instructor.

## ✅ Validación Implementada

### Método en ApiService
```dart
static Future<bool> canContactInstructor(int instructorId) async {
  // Verifica si existe al menos un pago con status='paid' 
  // para una clase con ese instructor
}
```

### Verificación en ChatScreen
- Al abrir el chat, se verifica automáticamente si el estudiante puede contactar
- Si NO tiene pago confirmado: muestra pantalla de bloqueo
- Si SÍ tiene pago confirmado: permite enviar mensajes

### Validación al Enviar
- Antes de enviar cada mensaje, se verifica nuevamente
- Si no tiene pago: muestra error "Debes tener un pago confirmado..."

## 🎯 Flujo de Usuario

### Estudiante SIN pago confirmado:
1. Intenta abrir chat con instructor
2. Ve pantalla con 🔒 y mensaje:
   - "Pago requerido"
   - "Debes tener un pago confirmado para contactar a este instructor"
3. No puede enviar mensajes

### Estudiante CON pago confirmado:
1. Abre chat con instructor
2. Ve historial de mensajes (si existe)
3. Puede enviar mensajes normalmente

## 📋 Condiciones para Contactar

Un estudiante puede contactar a un instructor si cumple:
```
✅ Tiene al menos 1 pago con status = 'paid'
✅ Ese pago está asociado a una clase del instructor
```

## 🔧 Archivos Modificados

1. **`lib/services/api_service.dart`**
   - Agregado método `canContactInstructor(instructorId)`

2. **`lib/screens/chat_screen.dart`**
   - Verificación al cargar pantalla
   - Verificación al enviar mensaje
   - UI de bloqueo cuando no tiene acceso

## 💡 Ejemplo de Uso

```dart
// Antes de navegar al chat, puedes verificar:
final canContact = await ApiService.canContactInstructor(instructorId);

if (canContact) {
  Navigator.pushNamed(context, ChatScreen.routeName, arguments: {...});
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Debes pagar una clase primero')),
  );
}
```

## 🎨 UI de Bloqueo

Cuando el estudiante no tiene acceso, ve:
```
┌─────────────────────┐
│                     │
│       🔒            │
│                     │
│  Pago requerido     │
│                     │
│  Debes tener un     │
│  pago confirmado    │
│  para contactar a   │
│  este instructor    │
│                     │
└─────────────────────┘
```

## ⚠️ Notas Importantes

- La verificación se hace en **tiempo real** cada vez
- Solo pagos con `status = 'paid'` son válidos
- El instructor puede ver y responder mensajes sin restricción
- Las conversaciones existentes se mantienen, pero no se pueden enviar nuevos mensajes sin pago

## 🔄 Actualización de Documentación

Los siguientes archivos de documentación anterior siguen siendo válidos, pero ahora con esta restricción adicional:
- `MESSAGING_README.md`
- `docs/MESSAGING_INTEGRATION.md`
- `INTEGRATION_EXAMPLE.dart`

---

**Restricción activa desde:** Ahora
**Afecta a:** Solo estudiantes contactando instructores
**No afecta a:** Instructores respondiendo a estudiantes
