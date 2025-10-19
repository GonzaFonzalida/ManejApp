# 🔒 ManejApp - Documentación de Seguridad

## 📋 Resumen de Implementaciones de Seguridad

### ✅ Medidas Implementadas

#### 🛡️ **1. Rate Limiting**
- **General**: 100 requests por 15 minutos por IP
- **Autenticación**: 5 intentos por 15 minutos para login/refresh
- **Configuración**: Variables de entorno personalizables
- **Ubicación**: `src/shared/middlewares/security.ts`

#### 🌐 **2. CORS (Cross-Origin Resource Sharing)**
- **Desarrollo**: localhost permitido
- **Producción**: Dominios específicos configurables
- **Headers controlados**: Content-Type, Authorization, X-Requested-With
- **Métodos permitidos**: GET, POST, PUT, DELETE, PATCH

#### 🔒 **3. Helmet - Headers de Seguridad**
- Content Security Policy (CSP)
- X-Frame-Options (Clickjacking protection)
- X-Content-Type-Options
- Referrer-Policy
- X-XSS-Protection

#### ✅ **4. Validación de Entrada Avanzada**
- **Sanitización automática** de inputs
- **Prevención SQL Injection** con patrones de detección
- **Prevención XSS** con limpieza de scripts maliciosos
- **Validación con Zod** para esquemas tipados
- **Express-validator** para validaciones específicas

#### 🔑 **5. Sistema de Autenticación Mejorado**
- **JWT Blacklisting** para logout inmediato
- **Rate limiting específico** para endpoints de auth
- **Tokens con expiración** configurable
- **Refresh tokens** seguros con httpOnly cookies

#### 📊 **6. Monitoreo y Auditoría**
- **Health Check** endpoint (`/health`)
- **Audit Logging** para acciones críticas
- **Request Logging** con performance tracking
- **Error Logging** centralizado

#### 🏗️ **7. Arquitectura Segura**
- **API Versioning** (`/api/v1/`)
- **Response Standardization** con formato consistente
- **Error Handling** sin exposición de información sensible
- **Input Size Limits** (10MB por request)

#### 💳 **8. Sistema de Pagos Seguro**
- **Transacciones atómicas** con rollback automático
- **Recovery automático** para pagos fallidos
- **Webhook signature validation** con HMAC SHA-256
- **Idempotencia** para prevenir pagos duplicados
- **Rate limiting específico** para pagos (10/15min)
- **Auditoría completa** de transacciones
- **Verificación de integridad** con Mercado Pago

---

## 🔧 Configuración de Variables de Entorno

```env
# Seguridad - Rate Limiting
RATE_LIMIT_WINDOW_MS="900000"         # 15 minutos
RATE_LIMIT_MAX_REQUESTS="100"        # Requests por ventana
AUTH_RATE_LIMIT_MAX="5"              # Intentos de auth por ventana

# JWT Seguridad
JWT_SECRET="your-super-secret-jwt-key-minimum-32-characters-long"
JWT_REFRESH_SECRET="your-super-secret-refresh-key-minimum-32-characters-long"
JWT_EXPIRATION="15m"
JWT_REFRESH_EXPIRATION="7d"

# Cookies Seguras
COOKIE_SECRET="your-super-secret-cookie-key-minimum-32-characters-long"

# Payment Security & Recovery
MERCADOPAGO_WEBHOOK_SECRET="your-webhook-secret-key"
MAX_PAYMENT_AMOUNT="1000000"
PAYMENT_RATE_LIMIT_MAX="10"
WEBHOOK_RATE_LIMIT_MAX="100"
PAYMENT_RECOVERY_INTERVAL="300000"    # 5 minutos
PAYMENT_STUCK_TIMEOUT="600000"       # 10 minutos
```

---

## 🚨 Consideraciones para el Frontend

### 🔐 **Autenticación y Autorización**

#### ✅ **Implementar**
```javascript
// Interceptor para manejar tokens expirados
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token expirado - intentar refresh
      try {
        await refreshToken();
        return axios.request(error.config);
      } catch {
        // Redirect a login
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);
```

#### ✅ **Headers de Seguridad**
```javascript
// Siempre incluir headers necesarios
const apiClient = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest'
  },
  withCredentials: true // Para cookies httpOnly
});
```

### 🛡️ **Validación del Cliente**

#### ✅ **Validación Dual**
- **Nunca confiar solo en validación frontend**
- **Implementar validación en ambos lados**
- **Mostrar errores de validación del servidor**

```javascript
// Ejemplo de validación frontend que complementa backend
const validatePassword = (password) => {
  const minLength = password.length >= 8;
  const hasUpper = /[A-Z]/.test(password);
  const hasLower = /[a-z]/.test(password);
  const hasNumber = /\d/.test(password);
  const hasSpecial = /[@$!%*?&]/.test(password);
  
  return minLength && hasUpper && hasLower && hasNumber && hasSpecial;
};
```

### 🔒 **Manejo Seguro de Datos**

#### ✅ **Almacenamiento Seguro**
```javascript
// ❌ NUNCA hacer esto
localStorage.setItem('token', jwtToken);
sessionStorage.setItem('user', JSON.stringify(userData));

// ✅ Usar cookies httpOnly (manejadas por el servidor)
// ✅ Para datos no sensibles, usar sessionStorage con cuidado
sessionStorage.setItem('userPreferences', JSON.stringify(preferences));
```

#### ✅ **Sanitización de Inputs**
```javascript
// Sanitizar inputs antes de mostrar
const sanitizeHTML = (str) => {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
};

// Usar librerías como DOMPurify para contenido HTML
import DOMPurify from 'dompurify';
const cleanHTML = DOMPurify.sanitize(userInput);
```

### 🚨 **Rate Limiting - Manejo en Frontend**

#### ✅ **Manejo de Rate Limits**
```javascript
// Manejar respuestas 429 (Too Many Requests)
axios.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 429) {
      const retryAfter = error.response.headers['retry-after'];
      showNotification(`Demasiadas solicitudes. Intenta en ${retryAfter}`, 'warning');
      
      // Deshabilitar botones temporalmente
      disableFormSubmission(retryAfter * 1000);
    }
    return Promise.reject(error);
  }
);
```

### 📱 **Experiencia de Usuario Segura**

#### ✅ **Feedback de Seguridad**
- **Mostrar indicadores de conexión segura**
- **Timeouts de sesión con advertencias**
- **Confirmaciones para acciones críticas**
- **Indicadores de fuerza de contraseña**

#### ✅ **Manejo de Errores**
```javascript
// No exponer detalles técnicos al usuario
const handleApiError = (error) => {
  const userMessage = error.response?.data?.error || 'Ha ocurrido un error';
  
  // Log técnico para desarrolladores (solo en desarrollo)
  if (process.env.NODE_ENV === 'development') {
    console.error('API Error:', error.response?.data);
  }
  
  // Mensaje amigable para el usuario
  showNotification(userMessage, 'error');
};
```

### 🔐 **Logout Seguro**

#### ✅ **Implementación de Logout**
```javascript
const logout = async () => {
  try {
    // Llamar endpoint de logout para invalidar tokens
    await apiClient.post('/auth/logout');
  } catch (error) {
    console.error('Logout error:', error);
  } finally {
    // Limpiar estado local independientemente del resultado
    clearUserState();
    window.location.href = '/login';
  }
};
```

---

## 🔍 Endpoints de Seguridad

### 📊 **Health Check**
```
GET /health
```
**Respuesta:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "uptime": 3600,
  "environment": "development",
  "services": {
    "database": "connected",
    "api": "running"
  }
}
```

### 🔐 **Autenticación**
```
POST /api/v1/auth/login     # Rate limited: 5/15min
POST /api/v1/auth/refresh   # Rate limited: 5/15min
POST /api/v1/auth/logout    # Invalida tokens
```

### 💳 **Pagos Seguros**
```
POST /api/v1/payments                    # Rate limited: 10/15min, requiere Idempotency-Key
POST /api/v1/payments/{id}/process       # Procesamiento con retry automático
POST /api/v1/payments/{id}/refund        # Sistema de reembolsos
POST /api/v1/payments/mercadopago/webhook # Webhook con validación de firma
POST /api/v1/payments/recovery/run       # Recovery manual de pagos stuck
GET  /api/v1/payments/{id}/verify        # Verificación de integridad
```

---

## ⚠️ **Alertas de Seguridad**

### 🚨 **CRÍTICO - Nunca hacer:**
1. **Exponer secrets** en el código frontend
2. **Almacenar tokens JWT** en localStorage
3. **Confiar únicamente** en validación frontend
4. **Ignorar headers CORS** en producción
5. **Usar HTTP** en producción (siempre HTTPS)

### ⚡ **IMPORTANTE - Siempre hacer:**
1. **Validar en servidor** todos los inputs
2. **Usar HTTPS** en producción
3. **Implementar timeouts** de sesión
4. **Manejar errores** sin exponer detalles técnicos
5. **Actualizar dependencias** regularmente

---

## 📈 **Próximas Mejoras Recomendadas**

### 🔄 **Corto Plazo**
- [ ] Implementar 2FA (Two-Factor Authentication)
- [ ] Agregar captcha en formularios críticos
- [ ] Implementar session management avanzado
- [ ] Agregar IP whitelisting para admin

### 🚀 **Mediano Plazo**
- [ ] Implementar WAF (Web Application Firewall)
- [ ] Agregar monitoreo de seguridad en tiempo real
- [ ] Implementar encryption at rest
- [ ] Agregar compliance logging (GDPR, etc.)

### 🏢 **Largo Plazo**
- [ ] Implementar zero-trust architecture
- [ ] Agregar threat detection automático
- [ ] Implementar security scanning automático
- [ ] Agregar penetration testing regular

---

## 📞 **Contacto de Seguridad**

Para reportar vulnerabilidades de seguridad:
- **Email**: security@manejapp.com
- **Proceso**: Responsible disclosure
- **Tiempo de respuesta**: 48 horas

---

---

## 📚 **Documentación Adicional**

- **[Sistema de Recuperación de Pagos](./PAYMENT-RECOVERY-SYSTEM.md)** - Documentación completa del sistema de recovery
- **[Seguridad de Pagos](./PAYMENTS-SECURITY.md)** - Guía detallada de seguridad en pagos
- **[Lista de Verificación](./SECURITY-CHECKLIST.md)** - Checklist de implementación

---

*Última actualización: Enero 2024*
*Versión de seguridad: 2.0.0 - Enhanced Payment Security*