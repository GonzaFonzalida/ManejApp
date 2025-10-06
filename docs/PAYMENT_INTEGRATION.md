# Integración de Pagos - Mercado Pago

## Descripción
Sistema de pagos integrado con Mercado Pago para procesar pagos de clases de manejo.

## Características Principales

### Creación de Preferencias
- **Generación automática** de preferencias de pago
- **Metadata personalizada** con información de la clase
- **URLs de callback** para manejo de estados
- **Integración con clases de manejo**

### Procesamiento de Pagos
- **Webhooks** para notificaciones de estado
- **Actualización automática** de estado de pagos
- **Manejo de estados**: pending, paid, failed
- **Validación de transacciones**

### Flujo de Pago
1. Usuario reserva clase
2. Sistema crea preferencia en Mercado Pago
3. Usuario es redirigido a checkout
4. Mercado Pago procesa el pago
5. Webhook actualiza estado en backend
6. Usuario ve confirmación de pago

## Archivos Clave
- `lib/screens/payment_screen.dart` - Interfaz de pago
- `lib/services/api_service.dart` - Endpoints de Mercado Pago
- Backend: Webhooks y procesamiento

## Estados de Pago
- **pending**: Pago pendiente de procesamiento
- **paid**: Pago completado exitosamente
- **failed**: Pago falló o fue rechazado

## Configuración
- **Sandbox**: Para pruebas (monto $1)
- **Production**: Para pagos reales
- **Access Token**: Configurado en backend
- **Webhook URL**: Para notificaciones automáticas