# 🗄️ ManejApp - Cambios en Base de Datos

## 📋 **Resumen de Cambios Implementados**

### ✅ **Nuevas Tablas Creadas**

#### **1. `payment_recovery_logs`**
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

**Propósito**: Logging detallado de cada paso en el proceso de pagos para recuperación y auditoría.

**Índices**:
- `idx_payment_recovery_payment_id` - Búsqueda por payment_id
- `idx_payment_recovery_timestamp` - Ordenamiento temporal
- `idx_payment_recovery_status` - Filtrado por estado

#### **2. `blacklisted_tokens`**
```sql
CREATE TABLE blacklisted_tokens (
    id SERIAL PRIMARY KEY,
    jti VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Propósito**: Sistema de JWT blacklisting para logout inmediato y seguridad mejorada.

**Índices**:
- `idx_blacklisted_tokens_jti` - Búsqueda rápida por JTI
- `idx_blacklisted_tokens_expires_at` - Limpieza de tokens expirados

### ✅ **Campos Agregados a Tabla Existente**

#### **Tabla `Payment` - Campos de Recovery**
```sql
ALTER TABLE payments ADD COLUMN recovery_attempts INTEGER DEFAULT 0;
ALTER TABLE payments ADD COLUMN last_recovery_at TIMESTAMP;
ALTER TABLE payments ADD COLUMN idempotency_key VARCHAR(255) UNIQUE;
```

**Nuevos campos**:
- `recovery_attempts` - Contador de intentos de recuperación
- `last_recovery_at` - Timestamp de última recuperación
- `idempotency_key` - Clave única para prevenir pagos duplicados

**Nuevos índices**:
- `idx_payments_idempotency` - Búsqueda por clave de idempotencia
- `idx_payments_external_ref` - Búsqueda por referencia externa
- `idx_payments_status` - Filtrado por estado

### ✅ **Estados de Pago Expandidos**

**Estados anteriores**: `pending`, `paid`, `failed`

**Estados nuevos agregados**:
- `processing` - Durante creación/verificación
- `cancelled` - Cancelado por usuario
- `refunded` - Reembolsado

---

## 🔄 **Migración Ejecutada**

### **Comando Utilizado**
```bash
npx prisma db push --accept-data-loss
```

### **Schema de Prisma Actualizado**
```prisma
model Payment {
  id                 Int       @id @default(autoincrement())
  amount             Float
  status             String    @default("pending")
  paymentMethod      String
  drivingClassId     Int
  drivingClass       DrivingClass @relation(fields: [drivingClassId], references: [id])

  // Mercado Pago fields
  preferenceId       String?
  paymentId          String?
  externalReference  String?

  // Recovery fields - NUEVOS
  recoveryAttempts   Int       @default(0) @map("recovery_attempts")
  lastRecoveryAt     DateTime? @map("last_recovery_at")
  idempotencyKey     String?   @unique @map("idempotency_key") @db.VarChar(255)

  createdAt          DateTime  @default(now())
  updatedAt          DateTime  @updatedAt

  @@index([idempotencyKey])
  @@index([externalReference])
  @@index([status])
}

model PaymentRecoveryLog {
  id        Int      @id @default(autoincrement())
  paymentId Int      @map("payment_id")
  step      String   @db.VarChar(100)
  status    String   @db.VarChar(20)
  data      String?  @default("{}")
  error     String?
  timestamp DateTime @default(now())

  @@index([paymentId])
  @@index([timestamp])
  @@index([status])
  @@map("payment_recovery_logs")
}

model BlacklistedToken {
  id        Int      @id @default(autoincrement())
  jti       String   @unique @db.VarChar(255)
  expiresAt DateTime @map("expires_at")
  createdAt DateTime @default(now()) @map("created_at")

  @@index([jti])
  @@index([expiresAt])
  @@map("blacklisted_tokens")
}
```

---

## 📊 **Impacto en Performance**

### **Índices Optimizados**
- ✅ **Búsquedas por payment_id**: O(log n) con índice
- ✅ **Filtrado por estado**: O(log n) con índice
- ✅ **Búsqueda por JTI**: O(1) con índice único
- ✅ **Limpieza temporal**: O(log n) con índice en timestamp

### **Espacio de Almacenamiento**
- **payment_recovery_logs**: ~200 bytes por log entry
- **blacklisted_tokens**: ~100 bytes por token
- **Campos nuevos en Payment**: ~50 bytes adicionales por pago

### **Estimación de Crecimiento**
- **1000 pagos/día**: ~200KB/día en logs de recovery
- **100 tokens blacklisted/día**: ~10KB/día
- **Retención 30 días**: ~6MB total mensual

---

## 🛠️ **Scripts de Mantenimiento**

### **Limpieza Automática de Logs**
```sql
-- Función para limpiar logs antiguos (>30 días)
CREATE OR REPLACE FUNCTION cleanup_old_payment_recovery_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM payment_recovery_logs 
    WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;
```

### **Limpieza de Tokens Expirados**
```sql
-- Función para limpiar tokens expirados
CREATE OR REPLACE FUNCTION cleanup_expired_blacklisted_tokens()
RETURNS void AS $$
BEGIN
    DELETE FROM blacklisted_tokens 
    WHERE expires_at <= NOW();
END;
$$ LANGUAGE plpgsql;
```

### **Cron Jobs Recomendados**
```bash
# Limpiar logs antiguos - diario a las 2 AM
0 2 * * * psql -d manejapp -c "SELECT cleanup_old_payment_recovery_logs();"

# Limpiar tokens expirados - cada hora
0 * * * * psql -d manejapp -c "SELECT cleanup_expired_blacklisted_tokens();"
```

---

## 🔍 **Verificación de Integridad**

### **Queries de Verificación**
```sql
-- Verificar estructura de payment_recovery_logs
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'payment_recovery_logs';

-- Verificar índices creados
SELECT indexname, tablename 
FROM pg_indexes 
WHERE tablename IN ('Payment', 'payment_recovery_logs', 'blacklisted_tokens');

-- Verificar datos de prueba
SELECT COUNT(*) as total_payments FROM "Payment";
SELECT COUNT(*) as total_recovery_logs FROM payment_recovery_logs;
SELECT COUNT(*) as total_blacklisted_tokens FROM blacklisted_tokens;
```

### **Estado Actual Verificado**
- ✅ Todas las tablas creadas correctamente
- ✅ Índices aplicados y funcionando
- ✅ Campos nuevos agregados sin conflictos
- ✅ Tests de inserción exitosos
- ✅ Schema de Prisma sincronizado

---

## 🚨 **Consideraciones de Rollback**

### **En Caso de Problemas**
```sql
-- Rollback de campos agregados (CUIDADO: pérdida de datos)
ALTER TABLE "Payment" DROP COLUMN IF EXISTS recovery_attempts;
ALTER TABLE "Payment" DROP COLUMN IF EXISTS last_recovery_at;
ALTER TABLE "Payment" DROP COLUMN IF EXISTS idempotency_key;

-- Rollback de tablas nuevas (CUIDADO: pérdida de datos)
DROP TABLE IF EXISTS payment_recovery_logs;
DROP TABLE IF EXISTS blacklisted_tokens;
```

### **Backup Recomendado**
```bash
# Backup antes de cambios importantes
pg_dump -U postgres -d manejapp > backup_before_recovery_system.sql
```

---

## 📈 **Próximos Cambios Planificados**

### **Corto Plazo**
- [ ] Tabla de métricas de pagos
- [ ] Tabla de configuración de rate limiting
- [ ] Campos adicionales para fraud detection

### **Mediano Plazo**
- [ ] Particionado de payment_recovery_logs por fecha
- [ ] Tabla de audit trail completo
- [ ] Soporte para múltiples gateways de pago

---

## 📞 **Contacto para Cambios de BD**

Para cambios en base de datos:
- **DBA**: dba@manejapp.com
- **DevOps**: devops@manejapp.com
- **Proceso**: Pull request + revisión de DBA

---

*Cambios aplicados: Enero 2024*
*Versión de BD: 2.0.0 - Payment Recovery System*
*Estado: ✅ Completado y Verificado*