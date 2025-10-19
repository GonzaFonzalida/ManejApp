# 💳 ManejApp - Documentación de Seguridad de Pagos

## 🔒 **Mejoras de Seguridad Implementadas**

### ✅ **1. Transacciones de Base de Datos**
- **Atomicidad**: Todas las operaciones críticas usan transacciones
- **Consistencia**: Validación de estados antes de cambios
- **Rollback automático**: En caso de errores durante el proceso

### ✅ **2. Rate Limiting Específico**
- **Pagos**: 10 intentos por 15 minutos por IP
- **Webhooks**: 100 requests por minuto (con excepciones para firmas válidas)
- **Protección contra ataques**: Previene spam y ataques de fuerza bruta

### ✅ **3. Validación de Firmas de Webhook**
- **Verificación criptográfica**: HMAC SHA-256
- **Timing-safe comparison**: Previene ataques de timing
- **Rechazo automático**: Webhooks sin firma válida son rechazados

### ✅ **4. Idempotencia**
- **Headers obligatorios**: `Idempotency-Key` requerido para creación
- **Prevención de duplicados**: Evita pagos accidentales múltiples
- **Consistencia**: Misma respuesta para misma clave

### ✅ **5. Validación Avanzada**
- **Montos**: Validación de rangos y formato
- **Métodos de pago**: Lista blanca de métodos permitidos
- **Clases de conducción**: Verificación de existencia y pertenencia

### ✅ **6. Retry Logic con Backoff**
- **Reintentos automáticos**: Para fallos de red temporales
- **Backoff exponencial**: Evita sobrecargar servicios externos
- **Límite de reintentos**: Máximo 3 intentos por operación

### ✅ **7. Auditoría Completa**
- **Logging de acciones**: Todas las operaciones críticas
- **Trazabilidad**: Seguimiento completo de cambios de estado
- **Información contextual**: IP, User-Agent, timestamps

---

## 🛡️ **Funcionalidades Nuevas**

### 💰 **Sistema de Reembolsos**
```typescript
// Reembolso completo
POST /api/v1/payments/{id}/refund
{
  "reason": "Cliente canceló la clase",
  "amount": 5000 // Opcional para reembolso parcial
}
```

### 📊 **Reportes de Pagos**
```typescript
// Reporte con filtros
GET /api/v1/payments/reports?startDate=2024-01-01&status=paid&method=mercadopago
```

### 🔄 **Verificación de Estado**
```typescript
// Verificar estado actual con Mercado Pago
GET /api/v1/payments/{id}/status
```

### 🎯 **Webhook Seguro**
```typescript
// Webhook con validación de firma
POST /api/v1/payments/mercadopago/webhook
Headers: {
  "X-Signature": "sha256=abc123..."
}
```

---

## 🔧 **Configuración Requerida**

### 📝 **Variables de Entorno**
```env
# Mercado Pago Webhook Security
MERCADOPAGO_WEBHOOK_SECRET="your-webhook-secret-key"

# Payment Limits
MAX_PAYMENT_AMOUNT="1000000"
PAYMENT_RATE_LIMIT_WINDOW="900000"  # 15 minutes
PAYMENT_RATE_LIMIT_MAX="10"         # 10 payments per window
```

### 🗄️ **Extensiones de Base de Datos**
```sql
-- Agregar campos para idempotencia
ALTER TABLE payments ADD COLUMN idempotency_key VARCHAR(255) UNIQUE;
ALTER TABLE payments ADD COLUMN refund_reason TEXT;
ALTER TABLE payments ADD COLUMN refunded_amount DECIMAL(10,2);

-- Índices para performance
CREATE INDEX idx_payments_idempotency ON payments(idempotency_key);
CREATE INDEX idx_payments_external_ref ON payments(external_reference);
CREATE INDEX idx_payments_created_at ON payments(created_at);
```

---

## 🚨 **Consideraciones para el Frontend**

### 🔐 **Headers Obligatorios**
```javascript
// Para crear pagos
const headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer ' + token,
  'Idempotency-Key': generateUniqueKey(), // UUID recomendado
};
```

### ⏱️ **Manejo de Rate Limiting**
```javascript
// Manejar respuestas 429
axios.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 429) {
      const retryAfter = error.response.headers['retry-after'];
      showMessage(`Demasiados intentos. Espera ${retryAfter} antes de intentar nuevamente.`);
      
      // Deshabilitar botón de pago temporalmente
      disablePaymentButton(retryAfter * 1000);
    }
    return Promise.reject(error);
  }
);
```

### 💳 **Validación de Montos**
```javascript
// Validar monto antes de enviar
const validateAmount = (amount) => {
  if (!amount || amount <= 0) {
    throw new Error('El monto debe ser mayor a 0');
  }
  
  if (amount > 1000000) {
    throw new Error('El monto excede el límite máximo');
  }
  
  // Redondear a 2 decimales
  return Math.round(amount * 100) / 100;
};
```

### 🔄 **Polling de Estado**
```javascript
// Verificar estado de pago periódicamente
const pollPaymentStatus = async (paymentId) => {
  const maxAttempts = 30; // 5 minutos máximo
  let attempts = 0;
  
  const poll = async () => {
    try {
      const response = await api.get(`/payments/${paymentId}/status`);
      const { status } = response.data.data;
      
      if (status === 'paid' || status === 'failed') {
        return status;
      }
      
      if (attempts < maxAttempts) {
        attempts++;
        setTimeout(poll, 10000); // Cada 10 segundos
      }
    } catch (error) {
      console.error('Error checking payment status:', error);
    }
  };
  
  return poll();
};
```

### 📱 **UX para Reembolsos**
```javascript
// Solicitar reembolso con confirmación
const requestRefund = async (paymentId, reason) => {
  const confirmed = await showConfirmDialog(
    '¿Estás seguro de que quieres solicitar un reembolso?',
    'Esta acción no se puede deshacer.'
  );
  
  if (confirmed) {
    try {
      await api.post(`/payments/${paymentId}/refund`, { reason });
      showSuccess('Reembolso solicitado exitosamente');
    } catch (error) {
      showError('Error al procesar el reembolso');
    }
  }
};
```

---

## 📈 **Métricas y Monitoreo**

### 📊 **KPIs de Pagos**
- **Tasa de éxito**: % de pagos completados exitosamente
- **Tiempo promedio**: Tiempo de procesamiento de pagos
- **Tasa de reembolsos**: % de pagos reembolsados
- **Métodos preferidos**: Distribución por método de pago

### 🚨 **Alertas Recomendadas**
- **Tasa de fallos > 10%**: Posible problema con gateway
- **Webhooks fallando**: Problema de conectividad
- **Rate limiting activado**: Posible ataque o mal uso
- **Reembolsos > 5%**: Revisar calidad del servicio

---

## 🔍 **Testing de Seguridad**

### 🧪 **Casos de Prueba**
1. **Rate Limiting**: Enviar más de 10 pagos en 15 minutos
2. **Webhook Signature**: Enviar webhook con firma inválida
3. **Idempotencia**: Crear pago con misma clave dos veces
4. **Validación**: Intentar pago con monto negativo
5. **Autorización**: Acceder a pagos de otro usuario

### 🛠️ **Herramientas Recomendadas**
- **Postman**: Para testing de APIs
- **Artillery**: Para load testing
- **OWASP ZAP**: Para security scanning
- **Webhook.site**: Para testing de webhooks

---

## 🚀 **Próximas Mejoras**

### 🔄 **Corto Plazo**
- [ ] Implementar circuit breaker para Mercado Pago
- [ ] Agregar métricas de performance
- [ ] Implementar cache para consultas frecuentes
- [ ] Agregar notificaciones push para pagos

### 🏢 **Mediano Plazo**
- [ ] Soporte para múltiples gateways de pago
- [ ] Implementar fraud detection
- [ ] Agregar soporte para suscripciones
- [ ] Implementar reconciliación automática

### 🌟 **Largo Plazo**
- [ ] Machine learning para detección de fraude
- [ ] Integración con sistemas contables
- [ ] Soporte para criptomonedas
- [ ] Análisis predictivo de pagos

---

*Última actualización: $(date)*
*Versión: 2.0.0 - Enhanced Security*