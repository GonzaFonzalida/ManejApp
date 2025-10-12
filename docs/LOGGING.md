# Sistema de Logging - ManejApp

## Descripción General

ManejApp incluye un sistema de logging robusto y configurable que sigue las mejores prácticas de la industria. El sistema está diseñado para proporcionar visibilidad completa de la aplicación, facilitar la depuración y el monitoreo.

## Características Principales

### **Niveles de Log**
- **ERROR**: Errores críticos que requieren atención inmediata
- **WARN**: Advertencias y errores esperados (ej: validaciones fallidas)
- **INFO**: Información general de la aplicación (requests, eventos de negocio)
- **DEBUG**: Información detallada para depuración

### **Múltiples Destinos (Transports)**
- **Console**: Salida colorizada para desarrollo
- **File**: Archivos con rotación automática
- **Database**: Almacenamiento en PostgreSQL con limpieza automática

### **Contexto Rico**
- Request ID único para correlación
- User ID y rol del usuario
- IP, User Agent, método HTTP
- Tiempo de respuesta
- Módulo y función donde ocurrió el log

### **Seguridad**
- Filtrado automático de datos sensibles (passwords, tokens, etc.)
- Headers y body sanitizados en logs

## Configuración

### Variables de Entorno

```env
# Nivel de logging
LOG_LEVEL="debug"                    # error, warn, info, debug

# Habilitar/deshabilitar transports
ENABLE_CONSOLE_LOGS="true"           
ENABLE_FILE_LOGS="true"              
ENABLE_DATABASE_LOGS="false"         

# Configuración de archivos
LOG_DIRECTORY="./logs"               
LOG_FILENAME="app.log"               
LOG_MAX_SIZE="50MB"                  
LOG_MAX_FILES="10"                   

# Configuración de base de datos
LOG_TABLE_NAME="logs"                
LOG_RETENTION_DAYS="30"              
```

### Configuración por Ambiente

- **Desarrollo**: Console + File (DEBUG level)
- **Producción**: File + Database (INFO level)
- **Testing**: Console only (ERROR level)

## Uso del Sistema

### Logging Básico

```typescript
import { logger } from '@shared/logging/LoggerConfig';

// Logs básicos
logger.error('Error crítico', error);
logger.warn('Advertencia importante');
logger.info('Información general');
logger.debug('Información de depuración');
```

### Logging con Contexto

```typescript
// Con contexto adicional
logger.error('Error en pago', error, {
  userId: 123,
  paymentId: 'pay_456',
  module: 'payments'
});

// Con metadata
logger.info('Pago procesado', {
  userId: 123,
  module: 'payments'
}, {
  amount: 1500,
  method: 'mercadopago'
});
```

### Logger por Request

```typescript
// En controladores, usar el logger del request
export const someController = (req: Request, res: Response) => {
  req.logger.info('Procesando request');
  
  try {
    // ... lógica
    req.logger.info('Request procesado exitosamente');
  } catch (error) {
    req.logger.error('Error procesando request', error);
  }
};
```

### Logging de Eventos de Negocio

```typescript
// Eventos importantes del negocio
logger.logBusinessEvent('instructor_registered', {
  userId: 123,
  instructorId: 456
});

logger.logSecurityEvent('failed_login_attempt', {
  ip: '192.168.1.1',
  email: 'user@example.com'
});
```

## Estructura de Logs

### Formato JSON

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "info",
  "message": "GET /api/users - 200 - 45ms",
  "context": {
    "requestId": "req_123456",
    "userId": 789,
    "userRole": "STUDENT",
    "ip": "192.168.1.1",
    "method": "GET",
    "url": "/api/users",
    "statusCode": 200,
    "responseTime": 45
  },
  "metadata": {
    "userAgent": "Mozilla/5.0..."
  }
}
```

### Logs de Error

```json
{
  "timestamp": "2024-01-15T10:30:00.000Z",
  "level": "error",
  "message": "Database connection failed",
  "context": {
    "requestId": "req_123456",
    "module": "database",
    "function": "connect"
  },
  "error": {
    "name": "ConnectionError",
    "message": "Connection timeout",
    "stack": "Error: Connection timeout\n    at ...",
    "code": "ETIMEDOUT"
  }
}
```

## Rotación de Archivos

Los archivos de log se rotan automáticamente:

- **Tamaño máximo**: 50MB por archivo
- **Archivos mantenidos**: 10 archivos rotados
- **Nomenclatura**: `app.log`, `app.1.log`, `app.2.log`, etc.

## Base de Datos

### Tabla de Logs

```sql
CREATE TABLE logs (
  id SERIAL PRIMARY KEY,
  timestamp TIMESTAMP NOT NULL,
  level VARCHAR(10) NOT NULL,
  message TEXT NOT NULL,
  context JSONB,
  error JSONB,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX idx_logs_timestamp ON logs(timestamp);
CREATE INDEX idx_logs_level ON logs(level);
CREATE INDEX idx_logs_request_id ON logs((context->>'requestId'));
```

### Limpieza Automática

Los logs en base de datos se limpian automáticamente cada 24 horas, manteniendo solo los logs de los últimos 30 días (configurable).

## Monitoreo y Alertas

### Métricas Importantes

- Número de errores por minuto/hora
- Requests lentos (>2 segundos)
- Fallos de autenticación
- Errores de base de datos

### Consultas Útiles

```sql
-- Errores en la última hora
SELECT * FROM logs 
WHERE level = 'error' 
AND timestamp > NOW() - INTERVAL '1 hour';

-- Requests lentos
SELECT * FROM logs 
WHERE context->>'responseTime' IS NOT NULL 
AND (context->>'responseTime')::int > 2000;

-- Errores por usuario
SELECT context->>'userId', COUNT(*) 
FROM logs 
WHERE level = 'error' 
GROUP BY context->>'userId';
```

## Mejores Prácticas

### **Qué Loggear**
- Inicio y fin de operaciones importantes
- Errores y excepciones
- Eventos de seguridad
- Cambios de estado importantes
- Requests HTTP (entrada y salida)

### ❌ **Qué NO Loggear**
- Passwords o tokens
- Información personal sensible
- Datos de tarjetas de crédito
- Logs excesivamente verbosos en producción

### 📝 **Formato de Mensajes**
- Usar mensajes descriptivos y consistentes
- Incluir contexto relevante
- Usar verbos en presente ("Processing payment", no "Processed payment")

## Troubleshooting

### Problemas Comunes

1. **Logs no aparecen**: Verificar nivel de log y configuración de transports
2. **Archivos muy grandes**: Ajustar `LOG_MAX_SIZE` y `LOG_MAX_FILES`
3. **Performance lenta**: Considerar deshabilitar database transport en desarrollo
4. **Espacio en disco**: Verificar rotación de archivos y limpieza de DB

### Debug del Sistema de Logging

```typescript
// Verificar configuración
console.log('Logger config:', {
  level: process.env.LOG_LEVEL,
  console: process.env.ENABLE_CONSOLE_LOGS,
  file: process.env.ENABLE_FILE_LOGS,
  database: process.env.ENABLE_DATABASE_LOGS
});

// Test básico
logger.debug('Test log message');
```

## Integración con Herramientas Externas

El sistema está preparado para integrarse con:

- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Grafana** + **Loki**
- **DataDog**
- **New Relic**
- **Sentry** (para errores)

Los logs en formato JSON facilitan la ingesta en estas herramientas.