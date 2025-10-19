# 🔄 ManejApp - Sistema de Recuperación de Pagos

## 📋 **Resumen del Sistema**

El sistema de recuperación de pagos garantiza que **ningún pago se pierda** durante fallos del sistema, proporcionando:

- ✅ **Transacciones atómicas** - Todo o nada
- ✅ **Logging detallado** - Cada paso registrado
- ✅ **Recovery automático** - Detección y corrección de pagos stuck
- ✅ **Verificación de integridad** - Sincronización con Mercado Pago
- ✅ **Auditoría completa** - Trazabilidad total

---

## 🗄️ **Estructura de Base de Datos**

### **Tabla: `payment_recovery_logs`**
```sql
CREATE TABLE payment_recovery_logs (
    id SERIAL PRIMARY KEY,
    payment_id INTEGER NOT NULL,
    step VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL, -- 'started', 'completed', 'failed'
    data TEXT DEFAULT '{}',
    error TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### **Tabla: `blacklisted_tokens`**
```sql
CREATE TABLE blacklisted_tokens (
    id SERIAL PRIMARY KEY,
    jti VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### **Campos Agregados a `Payment`**
```sql
ALTER TABLE payments ADD COLUMN recovery_attempts INTEGER DEFAULT 0;
ALTER TABLE payments ADD COLUMN last_recovery_at TIMESTAMP;
ALTER TABLE payments ADD COLUMN idempotency_key VARCHAR(255) UNIQUE;
```

---

## 🔄 **Flujo de Recuperación**

### **1. Proceso Normal de Pago**
```
payment_creation_started → payment_created → mp_preference_creation_started → 
mp_preference_created → payment_creation_completed
```

### **2. Detección de Pagos Stuck**
- Pagos en estado `processing` por más de 10 minutos
- Ejecuta automáticamente cada 5 minutos (recomendado)

### **3. Proceso de Recuperación**
```typescript
// Automático
await recoveryService.recoverFailedPayments();

// Manual para pago específico
const integrity = await recoveryService.verifyPaymentIntegrity(paymentId);
```

---

## 🛠️ **Servicios Implementados**

### **PaymentRecoveryService**
- `logPaymentStep()` - Registra cada paso del proceso
- `recoverFailedPayments()` - Recupera pagos stuck automáticamente
- `verifyPaymentIntegrity()` - Verifica consistencia con Mercado Pago
- `getRecoveryHistory()` - Obtiene historial de recuperación

### **EnhancedPaymentWithRecoveryService**
- `createPayment()` - Creación con logging completo
- `processPayment()` - Procesamiento con recovery automático
- `runRecoveryProcess()` - Ejecuta proceso de recuperación
- `verifyPayment()` - Verifica integridad de pago específico

---

## 🚨 **Escenarios de Fallo Cubiertos**

| Escenario | Protección | Recuperación |
|-----------|------------|--------------|
| **Falla de red con MP** | Retry automático | Sincronización posterior |
| **Timeout de BD** | Rollback automático | Estado consistente |
| **Crash del servidor** | Estados intermedios | Recovery al reiniciar |
| **Error en preferencia MP** | Transacción completa | Pago marcado como failed |
| **Webhook perdido** | Polling de estado | Sincronización automática |

---

## 📊 **Estados de Pago**

| Estado | Descripción | Recuperable |
|--------|-------------|-------------|
| `pending` | Creado, esperando pago | ✅ |
| `processing` | En proceso de creación/verificación | ✅ |
| `paid` | Confirmado exitosamente | ✅ |
| `failed` | Falló pero datos preservados | ✅ |
| `cancelled` | Cancelado por usuario | ✅ |
| `refunded` | Reembolsado | ✅ |

---

## 🔧 **Configuración y Uso**

### **Variables de Entorno**
```env
# Recovery automático
PAYMENT_RECOVERY_INTERVAL="300000"  # 5 minutos
PAYMENT_STUCK_TIMEOUT="600000"     # 10 minutos

# Logging
ENABLE_PAYMENT_RECOVERY_LOGS="true"
PAYMENT_LOG_RETENTION_DAYS="30"
```

### **Cron Job Recomendado**
```bash
# Cada 5 minutos
*/5 * * * * curl -X POST http://localhost:3000/api/v1/payments/recovery/run
```

### **Endpoints de Recovery**
```typescript
// Ejecutar recovery manual
POST /api/v1/payments/recovery/run

// Verificar integridad de pago
GET /api/v1/payments/{id}/verify

// Obtener historial de recovery
GET /api/v1/payments/{id}/recovery-history
```

---

## 📈 **Monitoreo y Alertas**

### **Métricas Clave**
- **Pagos stuck detectados** - Cantidad por hora
- **Recovery exitosos** - Tasa de recuperación
- **Inconsistencias MP** - Diferencias de estado/monto
- **Tiempo de recovery** - Duración promedio

### **Alertas Recomendadas**
- 🚨 **Más de 5 pagos stuck** en 1 hora
- 🚨 **Recovery fallando** por más de 30 minutos
- 🚨 **Inconsistencias MP** no resueltas
- 🚨 **Logs de recovery** creciendo rápidamente

---

## 🔍 **Verificación de Integridad**

### **Checks Automáticos**
```typescript
const integrity = await verifyPaymentIntegrity(paymentId);

// Resultado
{
  isConsistent: boolean,
  issues: [
    "Status mismatch: DB=pending, MP=paid",
    "Amount mismatch: DB=5000, MP=5000.50"
  ],
  recommendations: [
    "Sync status with Mercado Pago",
    "Verify payment amount"
  ]
}
```

### **Verificaciones Incluidas**
- ✅ **Estado vs Mercado Pago** - Consistencia de status
- ✅ **Monto vs Mercado Pago** - Verificación de amounts
- ✅ **Clase de conducción** - Existencia y relación
- ✅ **Timestamps** - Coherencia temporal
- ✅ **Referencias externas** - Validez de IDs

---

## 🛡️ **Garantías del Sistema**

### **Nivel de Protección: BANCARIO**

1. **Atomicidad Garantizada**
   - Transacciones con timeout de 30-60 segundos
   - Rollback automático en fallos
   - Estados intermedios seguros

2. **Durabilidad Asegurada**
   - Logging persistente en BD
   - Retención configurable (30 días default)
   - Backup automático de logs críticos

3. **Consistencia Verificada**
   - Sincronización automática con MP
   - Verificación de integridad programada
   - Corrección automática de inconsistencias

4. **Disponibilidad Mantenida**
   - Recovery automático sin intervención
   - Degradación graceful en fallos
   - Continuidad de servicio garantizada

---

## 📝 **Logs de Ejemplo**

### **Creación Exitosa**
```json
[
  {"step": "payment_creation_started", "status": "started", "timestamp": "2024-01-15T10:00:00Z"},
  {"step": "payment_created", "status": "completed", "data": {"paymentId": 123}},
  {"step": "mp_preference_creation_started", "status": "started"},
  {"step": "mp_preference_created", "status": "completed", "data": {"preferenceId": "MP-123"}},
  {"step": "payment_creation_completed", "status": "completed", "data": {"finalStatus": "pending"}}
]
```

### **Recovery Exitoso**
```json
[
  {"step": "recovery_started", "status": "started", "data": {"originalStatus": "processing"}},
  {"step": "mp_status_checked", "status": "completed", "data": {"mpStatus": "approved", "mappedStatus": "paid"}},
  {"step": "recovery_completed", "status": "completed", "data": {"recoveredStatus": "paid"}}
]
```

---

## 🚀 **Próximas Mejoras**

### **Corto Plazo**
- [ ] Dashboard de recovery en tiempo real
- [ ] Alertas automáticas por Slack/Email
- [ ] Métricas de performance detalladas
- [ ] Recovery predictivo con ML

### **Mediano Plazo**
- [ ] Multi-gateway recovery
- [ ] Recovery distribuido
- [ ] Blockchain audit trail
- [ ] Recovery como servicio (RaaS)

---

*Sistema implementado: Enero 2024*
*Nivel de protección: Bancario*
*Garantía: 0% pérdida de datos*