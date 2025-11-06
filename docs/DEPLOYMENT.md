# 🚀 ManejApp - Guía de Despliegue a Producción

## 📋 **Checklist Pre-Despliegue**

### ✅ **Base de Datos**
- [ ] **PostgreSQL configurado** en producción
- [ ] **Migración aplicada**: `npx prisma db push`
- [ ] **Datos de prueba** eliminados
- [ ] **Backup configurado** automáticamente

### ✅ **Variables de Entorno**
```env
# Producción
NODE_ENV="production"
DATABASE_URL="postgresql://user:pass@host:5432/manejapp_prod"
JWT_SECRET="super-secure-production-secret"
MERCADOPAGO_ACCESS_TOKEN="APP_USR-production-token"
APP_COMMISSION_PERCENTAGE="20"
FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
```

### ✅ **Mercado Pago**
- [ ] **Cuenta verificada** y aprobada
- [ ] **Marketplace habilitado**
- [ ] **Webhooks configurados**:
  - `https://yourdomain.com/api/v1/payments/webhook`
- [ ] **Certificados SSL** válidos

### ✅ **Firebase**
- [ ] **Proyecto creado** en Firebase Console
- [ ] **Service Account** generado
- [ ] **Push notifications** habilitadas

---

## 🏗️ **Opciones de Despliegue**

### **Opción 1: Railway (Recomendado)**
```bash
# 1. Instalar Railway CLI
npm install -g @railway/cli

# 2. Login y deploy
railway login
railway init
railway add postgresql
railway deploy
```

### **Opción 2: Render**
```bash
# 1. Conectar repositorio en render.com
# 2. Configurar variables de entorno
# 3. Deploy automático desde GitHub
```

### **Opción 3: DigitalOcean App Platform**
```bash
# 1. Crear app en DigitalOcean
# 2. Conectar repositorio
# 3. Configurar base de datos PostgreSQL
```

---

## 🔧 **Configuración del Servidor**

### **Dockerfile (si usas Docker)**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

### **Scripts de Producción**
```json
{
  "scripts": {
    "start": "node dist/index.js",
    "build": "tsc && tsc-alias",
    "postinstall": "npm run build",
    "db:deploy": "npx prisma db push",
    "db:seed": "npx prisma db seed"
  }
}
```

---

## 🔒 **Configuración de Seguridad**

### **SSL/HTTPS**
- ✅ **Certificado SSL** configurado
- ✅ **Redirección HTTP → HTTPS**
- ✅ **HSTS headers** habilitados

### **Firewall y Acceso**
```bash
# Solo puertos necesarios abiertos
- 80 (HTTP redirect)
- 443 (HTTPS)
- 5432 (PostgreSQL - solo desde app)
```

### **Variables Sensibles**
- ✅ **Nunca en código fuente**
- ✅ **Usar secrets del proveedor**
- ✅ **Rotación periódica**

---

## 📊 **Monitoreo y Logs**

### **Logs de Aplicación**
```bash
# Ver logs en tiempo real
tail -f /var/log/manejapp/app.log

# Logs por nivel
grep "ERROR" /var/log/manejapp/app.log
```

### **Métricas Importantes**
- **Uptime**: > 99.9%
- **Response time**: < 500ms
- **Error rate**: < 1%
- **Database connections**: < 80% del límite

### **Alertas Configurar**
- [ ] **Servidor caído**
- [ ] **Base de datos desconectada**
- [ ] **Pagos fallidos** > 5%
- [ ] **Uso de memoria** > 80%

---

## 🔄 **Proceso de Actualización**

### **Deploy Seguro**
```bash
# 1. Backup de BD
pg_dump manejapp_prod > backup_$(date +%Y%m%d).sql

# 2. Deploy en staging
git push staging main

# 3. Pruebas automáticas
npm run test:e2e

# 4. Deploy a producción
git push production main

# 5. Verificar salud del sistema
curl https://yourdomain.com/health
```

### **Rollback Plan**
```bash
# Si algo falla, rollback inmediato
git revert HEAD
git push production main

# Restaurar BD si es necesario
psql manejapp_prod < backup_YYYYMMDD.sql
```

---

## 🚨 **Troubleshooting Común**

### **Error: Base de datos no conecta**
```bash
# Verificar conexión
psql $DATABASE_URL

# Verificar variables
echo $DATABASE_URL
```

### **Error: Mercado Pago webhook falla**
```bash
# Verificar URL pública
curl -X POST https://yourdomain.com/api/v1/payments/webhook

# Verificar logs
grep "webhook" /var/log/manejapp/app.log
```

### **Error: Notificaciones no llegan**
```bash
# Verificar Firebase config
echo $FIREBASE_SERVICE_ACCOUNT_KEY | jq .

# Test notification
curl -X POST https://yourdomain.com/api/v1/notifications/test
```

---

## 📈 **Optimización de Performance**

### **Base de Datos**
```sql
-- Índices críticos
CREATE INDEX CONCURRENTLY idx_payments_status ON payments(status);
CREATE INDEX CONCURRENTLY idx_classes_date ON driving_classes(date);
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

### **Caché**
```bash
# Redis para sesiones (opcional)
npm install redis
```

### **CDN**
- **Archivos estáticos** → CloudFlare/AWS CloudFront
- **Imágenes** → Optimización automática

---

## 🎯 **Post-Despliegue**

### **Verificaciones Inmediatas**
- [ ] **Health check** responde OK
- [ ] **Login funciona** correctamente
- [ ] **Pago de prueba** se procesa
- [ ] **Notificación test** se envía
- [ ] **Dashboard admin** carga

### **Configuración Inicial**
```bash
# 1. Crear usuario admin
curl -X POST https://yourdomain.com/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@manejapp.com","password":"secure123","role":"ADMIN"}'

# 2. Configurar primer instructor
# 3. Probar flujo completo de pago
```

### **Documentación para Usuarios**
- [ ] **Manual de usuario** actualizado
- [ ] **FAQ** con problemas comunes
- [ ] **Contacto de soporte** configurado

---

## 📞 **Soporte y Mantenimiento**

### **Contactos Críticos**
- **Mercado Pago**: soporte técnico
- **Firebase**: documentación oficial
- **Hosting**: soporte del proveedor

### **Mantenimiento Programado**
- **Semanal**: Revisar logs de errores
- **Mensual**: Actualizar dependencias
- **Trimestral**: Backup completo y prueba de restauración

---

## 🎉 **¡Listo para Producción!**

Una vez completados todos los pasos:

1. ✅ **Sistema desplegado** y funcionando
2. ✅ **Pagos procesándose** correctamente
3. ✅ **Comisiones distribuyéndose** automáticamente
4. ✅ **Notificaciones enviándose**
5. ✅ **Monitoreo activo**

**¡ManejApp está listo para recibir usuarios reales!** 🚗💨

---

*Última actualización: Enero 2024*
*Versión: 1.0.0 - Production Ready*