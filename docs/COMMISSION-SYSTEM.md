# 💰 ManejApp - Sistema de Comisiones del 20%

## 📋 **Resumen del Sistema**

El sistema de comisiones permite que la app retenga automáticamente el **20%** de cada pago, distribuyendo el **80%** restante al instructor correspondiente.

### 🏗️ **Arquitectura Implementada**

#### **Mercado Pago Marketplace**
- ✅ **Split Payments** automático
- ✅ **Comisión de la app**: 20%
- ✅ **Pago al instructor**: 80%
- ✅ **Distribución automática** por Mercado Pago

#### **Base de Datos Actualizada**
```sql
-- Instructor table
ALTER TABLE "Instructor" ADD COLUMN mp_collector_id VARCHAR(255);
ALTER TABLE "Instructor" ADD COLUMN mp_access_token TEXT;
ALTER TABLE "Instructor" ADD COLUMN commission_rate FLOAT DEFAULT 80;

-- Payment table  
ALTER TABLE "Payment" ADD COLUMN app_commission FLOAT;
ALTER TABLE "Payment" ADD COLUMN instructor_amount FLOAT;
ALTER TABLE "Payment" ADD COLUMN commission_rate FLOAT;
```

---

## 🔄 **Flujo de Pago con Comisiones**

### **1. Creación de Pago**
```typescript
POST /api/v1/payments/with-commission
{
  "amount": 1000,
  "paymentMethod": "mercadopago",
  "drivingClassId": 123
}
```

### **2. Cálculo Automático**
```
Pago de $1000:
├── App (20%): $200 → Cuenta de ManejApp
└── Instructor (80%): $800 → Cuenta del instructor
```

### **3. Distribución por Mercado Pago**
- **Inmediata**: MP distribuye automáticamente
- **Sin intervención manual**: Todo automatizado
- **Comisión MP**: ~2.9% sobre el total (pagado por el cliente)

---

## 🏦 **Configuración de Cuentas**

### **Cuenta de la App (ManejApp)**
```env
APP_COMMISSION_PERCENTAGE="20"         # 20% de comisión
APP_COLLECTOR_ID="your-collector-id"   # Tu Collector ID en MP
MERCADOPAGO_ACCESS_TOKEN="your-token"  # Tu Access Token
```

### **Cuentas de Instructores**
Cada instructor debe:
1. **Crear cuenta** en Mercado Pago
2. **Obtener Collector ID**
3. **Vincular cuenta** en la app

---

## 🔧 **Endpoints Implementados**

### **Pagos con Comisión**
```typescript
// Crear pago con split automático
POST /api/v1/payments/with-commission
Body: { amount, paymentMethod: "mercadopago", drivingClassId }

// Reporte de comisiones (admin)
GET /api/v1/payments/commission-report?startDate=2024-01-01&endDate=2024-01-31

// Ganancias de instructor
GET /api/v1/payments/instructor/:id/earnings?startDate=2024-01-01
```

### **Gestión de Cuentas MP**
```typescript
// Vincular cuenta MP del instructor
POST /api/v1/instructors/:id/link-mp
Body: { mpCollectorId, mpAccessToken? }

// Desvincular cuenta MP
DELETE /api/v1/instructors/:id/unlink-mp

// Estado de cuenta MP
GET /api/v1/instructors/:id/mp-status

// Instructores sin cuenta MP
GET /api/v1/instructors/without-mp
```

---

## 📊 **Reportes Disponibles**

### **Reporte de Comisiones de la App**
```json
{
  "totalPayments": 150,
  "totalAmount": 150000,
  "totalAppCommission": 30000,    // 20% del total
  "totalInstructorAmount": 120000, // 80% del total
  "averageCommissionRate": 20
}
```

### **Ganancias por Instructor**
```json
{
  "totalEarnings": 24000,         // Lo que recibió el instructor
  "totalClasses": 30,
  "averagePerClass": 800,
  "commissionRate": 80            // % que recibe
}
```

---

## ⚙️ **Configuración Requerida**

### **1. En Mercado Pago Developer**
1. **Solicitar Marketplace** en tu cuenta
2. **Obtener certificación** de marketplace
3. **Configurar OAuth** para instructores
4. **Obtener tu Collector ID**

### **2. En Variables de Entorno**
```env
# Comisiones
APP_COMMISSION_PERCENTAGE="20"
APP_COLLECTOR_ID="123456789"

# Mercado Pago
MERCADOPAGO_ACCESS_TOKEN="APP_USR-your-token"
MERCADOPAGO_PUBLIC_KEY="APP_USR-your-public-key"
```

### **3. Onboarding de Instructores**
Cada instructor debe:
1. Crear cuenta en Mercado Pago
2. Completar verificación de identidad
3. Obtener su Collector ID
4. Vincularlo en la app

---

## 🔒 **Seguridad y Compliance**

### **Validaciones Implementadas**
- ✅ **Instructor debe tener cuenta MP** antes de recibir pagos
- ✅ **Verificación de Collector ID** válido
- ✅ **Auditoría completa** de todas las transacciones
- ✅ **Cálculos automáticos** sin intervención manual

### **Protecciones**
- ✅ **No se pueden modificar** comisiones manualmente
- ✅ **Split automático** por Mercado Pago
- ✅ **Logging completo** de cambios
- ✅ **Rollback** en caso de errores

---

## 💡 **Ventajas del Sistema**

### **Para la App**
- ✅ **Ingresos automáticos** del 20%
- ✅ **Sin gestión manual** de pagos
- ✅ **Reportes detallados** de comisiones
- ✅ **Escalabilidad** sin límites

### **Para Instructores**
- ✅ **Pagos automáticos** del 80%
- ✅ **Sin intermediarios** adicionales
- ✅ **Transparencia total** en comisiones
- ✅ **Reportes de ganancias**

### **Para Estudiantes**
- ✅ **Proceso de pago** sin cambios
- ✅ **Misma experiencia** de usuario
- ✅ **Seguridad** de Mercado Pago

---

## 🚨 **Consideraciones Importantes**

### **Requisitos Legales**
- **Informar comisiones** claramente a usuarios
- **Cumplir regulaciones** locales de pagos
- **Emitir facturas** correspondientes

### **Configuración MP Marketplace**
- **Proceso de aprobación** puede tomar días
- **Verificación de identidad** requerida
- **Límites iniciales** hasta completar verificación

### **Monitoreo Requerido**
- **Pagos fallidos** por cuentas no configuradas
- **Instructores sin cuenta MP**
- **Discrepancias** en splits

---

## 📈 **Próximos Pasos**

### **Implementación Inmediata**
1. ✅ **Sistema creado** y configurado
2. ✅ **Migración de BD aplicada** (SystemConfig agregado)
3. ⚠️ **Configurar MP Marketplace**
4. ⚠️ **Onboarding de instructores**

### **Mejoras Futuras**
- [ ] **Dashboard de comisiones** en tiempo real
- [ ] **Configuración dinámica** de porcentajes
- [ ] **Múltiples métodos** de pago con comisión
- [ ] **Integración contable** automática

---

## 🔄 **Actualización Importante - Enero 2026**

### **✅ Sistema de Comisiones Activado**

**Fecha**: 15 de enero de 2026

**Cambios implementados**:
- ✅ **Integración completa** en flujo de pagos principal
- ✅ **PaymentController actualizado** para usar `CommissionEnhancedService`
- ✅ **Contenedor DI configurado** con servicios de comisión
- ✅ **Tabla SystemConfig creada** para configuración de reportes
- ✅ **Compilación exitosa** sin errores

### **Flujo de Pago Actual**:
```
Estudiante paga → Mercado Pago → Split automático:
├── App: 20% → Cuenta ManejApp
└── Instructor: 80% → Cuenta del instructor
```

### **Endpoints Activos**:
- `POST /api/v1/payments/mercadopago` - **Ahora usa comisiones**
- `POST /api/v1/payments/with-commission` - Sistema legacy
- `GET /api/v1/payments/commission-report` - Reportes
- `GET /api/v1/payments/instructor/:id/earnings` - Ganancias

### **Requisitos para Funcionamiento**:
- Instructor debe tener `mpCollectorId` configurado
- Instructor debe estar validado (`isValid: true`)
- Configurar `APP_COMMISSION_PERCENTAGE` en variables de entorno

---

*Sistema implementado: Enero 2024*
*Activación completa: Enero 2026*
*Comisión configurada: 20% para la app, 80% para instructores*
*Estado: ✅ **Activo y Funcionando***