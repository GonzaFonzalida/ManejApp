# Sistema de Logging de Errores - ManejApp

## Descripción Técnica

El sistema de logging implementado en ManejApp constituye una solución empresarial robusta para la captura, procesamiento y almacenamiento de eventos de aplicación. La arquitectura está diseñada siguiendo patrones de observabilidad modernos, proporcionando trazabilidad completa de requests, correlación de eventos y análisis forense de errores.

## Arquitectura del Sistema

### Componentes Principales

```
┌─────────────────────────────────────────────────────────────┐
│                    Logger Core System                       │
├─────────────────────────────────────────────────────────────┤
│  LogEntry Interface  │  Logger Class  │  LoggerFactory     │
├─────────────────────────────────────────────────────────────┤
│                    Transport Layer                          │
├─────────────────────────────────────────────────────────────┤
│  ConsoleTransport   │  FileTransport  │  DatabaseTransport │
├─────────────────────────────────────────────────────────────┤
│                   Middleware Layer                          │
├─────────────────────────────────────────────────────────────┤
│  RequestLogger  │  ErrorLogger  │  PerformanceLogger       │
└─────────────────────────────────────────────────────────────┘
```

### Jerarquía de Niveles de Log

El sistema implementa una jerarquía estricta de niveles de severidad:

| Nivel   | Valor | Descripción                                    | Uso Recomendado                    |
|---------|-------|------------------------------------------------|------------------------------------|
| ERROR   | 0     | Errores críticos que requieren intervención   | Excepciones no controladas, fallos de sistema |
| WARN    | 1     | Advertencias y errores de negocio esperados   | Validaciones fallidas, recursos no encontrados |
| INFO    | 2     | Eventos informativos de operación normal      | Inicio de procesos, completación de operaciones |
| DEBUG   | 3     | Información detallada para diagnóstico        | Valores de variables, flujo de ejecución |

## Configuración del Sistema

### Variables de Entorno

```bash
# Configuración de Nivel de Logging
LOG_LEVEL=info                      # Nivel mínimo de logs a procesar

# Configuración de Transports
ENABLE_CONSOLE_LOGS=true            # Activar salida por consola
ENABLE_FILE_LOGS=true               # Activar persistencia en archivos
ENABLE_DATABASE_LOGS=false          # Activar almacenamiento en BD

# Configuración de Archivos
LOG_DIRECTORY=./logs                # Directorio de almacenamiento
LOG_FILENAME=app.log                # Nombre base del archivo
LOG_MAX_SIZE=50MB                   # Tamaño máximo antes de rotación
LOG_MAX_FILES=10                    # Número máximo de archivos rotados

# Configuración de Base de Datos
LOG_TABLE_NAME=logs                 # Nombre de la tabla de logs
LOG_RETENTION_DAYS=30               # Días de retención en base de datos
```

### Configuración por Ambiente

```typescript
// Desarrollo
{
  level: LogLevel.DEBUG,
  transports: [ConsoleTransport, FileTransport],
  enableConsole: true,
  enableFile: true,
  enableDatabase: false
}

// Producción
{
  level: LogLevel.INFO,
  transports: [FileTransport, DatabaseTransport],
  enableConsole: false,
  enableFile: true,
  enableDatabase: true
}
```

## Estructura de Datos

### Schema de LogEntry

```typescript
interface LogEntry {
  timestamp: Date;                    // Timestamp ISO 8601 UTC
  level: LogLevel;                    // Nivel de severidad
  message: string;                    // Mensaje descriptivo
  context?: LogContext;               // Contexto de ejecución
  error?: SerializedError;            // Información de error serializada
  metadata?: Record<string, any>;     // Datos adicionales estructurados
}
```

### Contexto de Request

```typescript
interface LogContext {
  requestId?: string;                 // UUID único del request
  userId?: number;                    // Identificador del usuario
  userRole?: string;                  // Rol del usuario (STUDENT|INSTRUCTOR|ADMIN)
  ip?: string;                        // Dirección IP del cliente
  userAgent?: string;                 // User-Agent del navegador
  method?: string;                    // Método HTTP (GET|POST|PUT|DELETE)
  url?: string;                       // URL del endpoint
  statusCode?: number;                // Código de respuesta HTTP
  responseTime?: number;              // Tiempo de respuesta en milisegundos
  module?: string;                    // Módulo de la aplicación
  function?: string;                  // Función específica
}
```

## Implementación de Transports

### ConsoleTransport

Proporciona salida formateada con colorización para entornos de desarrollo:

```typescript
// Características:
- Colorización por nivel de severidad
- Formato legible para desarrollo
- Filtrado de información sensible
- Stack traces expandidos para errores
```

### FileTransport

Implementa persistencia en archivos con rotación automática:

```typescript
// Características:
- Formato JSON estructurado
- Rotación por tamaño configurable
- Mantenimiento automático de archivos históricos
- Compresión opcional de archivos antiguos
- Nomenclatura secuencial (app.log, app.1.log, app.2.log)
```

### DatabaseTransport

Almacenamiento en PostgreSQL con índices optimizados:

```sql
-- Schema de tabla optimizada
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

-- Índices para consultas eficientes
CREATE INDEX idx_logs_timestamp ON logs(timestamp);
CREATE INDEX idx_logs_level ON logs(level);
CREATE INDEX idx_logs_request_id ON logs((context->>'requestId'));
CREATE INDEX idx_logs_user_id ON logs((context->>'userId'));
```

## Middleware de Request Logging

### RequestLoggerMiddleware

Intercepta y registra automáticamente todos los requests HTTP:

```typescript
// Funcionalidades:
- Generación de Request ID único (UUID v4)
- Captura de contexto completo del request
- Medición automática de tiempo de respuesta
- Logging de request/response con filtrado de datos sensibles
- Correlación de logs por Request ID
```

### ErrorLoggerMiddleware

Maneja el logging especializado de errores:

```typescript
// Características:
- Diferenciación entre errores esperados y críticos
- Captura de stack traces completos
- Contexto enriquecido con información del request
- Clasificación automática por tipo de error
```

### PerformanceLoggerMiddleware

Monitorea y registra métricas de rendimiento:

```typescript
// Métricas capturadas:
- Tiempo de respuesta por endpoint
- Detección de requests lentos (threshold configurable)
- Análisis de patrones de uso
- Identificación de cuellos de botella
```

## Seguridad y Privacidad

### Filtrado de Datos Sensibles

El sistema implementa filtrado automático de información confidencial:

```typescript
// Campos filtrados automáticamente:
const sensitiveFields = [
  'password', 'token', 'secret', 'key', 
  'authorization', 'creditCard', 'ssn', 'dni'
];

// Headers filtrados:
const sensitiveHeaders = [
  'authorization', 'cookie', 'x-api-key', 'x-auth-token'
];
```

### Cumplimiento de Normativas

- **GDPR**: Filtrado automático de datos personales
- **PCI DSS**: Exclusión de información de tarjetas de crédito
- **SOX**: Trazabilidad completa de transacciones financieras

## Patrones de Uso

### Logging en Servicios

```typescript
export class PaymentService {
  private logger = logger.child({ module: 'PaymentService' });

  async processPayment(paymentData: PaymentData): Promise<Payment> {
    this.logger.info('Iniciando procesamiento de pago', {
      function: 'processPayment'
    }, { paymentId: paymentData.id, amount: paymentData.amount });

    try {
      const result = await this.executePayment(paymentData);
      
      this.logger.logBusinessEvent('payment_processed', {
        function: 'processPayment'
      }, { paymentId: result.id, status: result.status });

      return result;
    } catch (error) {
      this.logger.error('Error en procesamiento de pago', error, {
        function: 'processPayment'
      }, { paymentData });
      throw error;
    }
  }
}
```

### Logging en Controladores

```typescript
export class PaymentController {
  createPayment = async (req: Request, res: Response, next: NextFunction) => {
    req.logger?.info('Procesando creación de pago', {
      module: 'PaymentController',
      function: 'createPayment'
    });

    try {
      const payment = await this.paymentService.createPayment(req.body);
      res.status(201).json(payment);
    } catch (error) {
      next(error); // El middleware de error se encarga del logging
    }
  };
}
```

## Consultas y Análisis

### Consultas de Diagnóstico

```sql
-- Errores críticos en las últimas 24 horas
SELECT timestamp, message, context->>'requestId', error
FROM logs 
WHERE level = 'error' 
  AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC;

-- Análisis de performance por endpoint
SELECT 
  context->>'url' as endpoint,
  AVG((context->>'responseTime')::int) as avg_response_time,
  COUNT(*) as request_count
FROM logs 
WHERE context->>'responseTime' IS NOT NULL
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY context->>'url'
ORDER BY avg_response_time DESC;

-- Detección de patrones de error por usuario
SELECT 
  context->>'userId' as user_id,
  COUNT(*) as error_count,
  array_agg(DISTINCT message) as error_types
FROM logs 
WHERE level IN ('error', 'warn')
  AND context->>'userId' IS NOT NULL
  AND timestamp > NOW() - INTERVAL '1 day'
GROUP BY context->>'userId'
HAVING COUNT(*) > 5
ORDER BY error_count DESC;
```

### Métricas de Monitoreo

```sql
-- Dashboard de métricas en tiempo real
WITH metrics AS (
  SELECT 
    DATE_TRUNC('minute', timestamp) as minute,
    level,
    COUNT(*) as count
  FROM logs 
  WHERE timestamp > NOW() - INTERVAL '1 hour'
  GROUP BY DATE_TRUNC('minute', timestamp), level
)
SELECT 
  minute,
  COALESCE(SUM(CASE WHEN level = 'error' THEN count END), 0) as errors,
  COALESCE(SUM(CASE WHEN level = 'warn' THEN count END), 0) as warnings,
  COALESCE(SUM(CASE WHEN level = 'info' THEN count END), 0) as info_logs
FROM metrics
GROUP BY minute
ORDER BY minute DESC;
```

## Mantenimiento y Operaciones

### Rotación de Archivos

```bash
# Configuración automática de rotación
LOG_MAX_SIZE=50MB     # Rotación cuando el archivo excede 50MB
LOG_MAX_FILES=10      # Mantener máximo 10 archivos históricos

# Estructura de archivos resultante:
logs/
├── app.log           # Archivo activo
├── app.1.log         # Rotación más reciente
├── app.2.log         # Segunda rotación
└── ...
└── app.10.log        # Rotación más antigua (se elimina al crear app.11.log)
```

### Limpieza de Base de Datos

```typescript
// Proceso automático ejecutado cada 24 horas
async cleanupOldLogs(): Promise<void> {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - this.retentionDays);
  
  await prisma.$executeRaw`
    DELETE FROM logs 
    WHERE created_at < ${cutoffDate}
  `;
}
```

## Integración con Herramientas de Monitoreo

### ELK Stack (Elasticsearch, Logstash, Kibana)

```json
// Configuración de Logstash para ingesta
input {
  file {
    path => "/app/logs/*.log"
    codec => "json"
  }
}

filter {
  if [level] == "error" {
    mutate { add_tag => ["alert"] }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch:9200"]
    index => "manejapp-logs-%{+YYYY.MM.dd}"
  }
}
```

### Grafana + Loki

```yaml
# Configuración de Promtail
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: manejapp
    static_configs:
      - targets:
          - localhost
        labels:
          job: manejapp
          __path__: /app/logs/*.log
```

## Consideraciones de Performance

### Optimizaciones Implementadas

1. **Logging Asíncrono**: Todos los transports operan de forma no bloqueante
2. **Buffering**: Escritura en lotes para reducir I/O
3. **Índices de Base de Datos**: Optimizados para consultas frecuentes
4. **Filtrado Temprano**: Evaluación de nivel antes del procesamiento
5. **Serialización Eficiente**: Minimización de overhead de JSON

### Métricas de Rendimiento

```typescript
// Benchmarks típicos (requests/segundo):
// - Console Transport: ~50,000 logs/sec
// - File Transport: ~10,000 logs/sec  
// - Database Transport: ~5,000 logs/sec
// - Overhead por request: <1ms adicional
```

## Troubleshooting

### Problemas Comunes y Soluciones

| Problema | Síntoma | Solución |
|----------|---------|----------|
| Logs no aparecen | Sin salida visible | Verificar `LOG_LEVEL` y configuración de transports |
| Archivos muy grandes | Consumo excesivo de disco | Ajustar `LOG_MAX_SIZE` y `LOG_MAX_FILES` |
| Performance degradada | Respuestas lentas | Deshabilitar `DatabaseTransport` en desarrollo |
| Errores de permisos | Fallos de escritura | Verificar permisos del directorio `LOG_DIRECTORY` |

### Comandos de Diagnóstico

```bash
# Verificar configuración actual
grep LOG_ .env

# Monitorear logs en tiempo real
tail -f logs/app.log | jq '.'

# Analizar errores recientes
grep '"level":"error"' logs/app.log | tail -10 | jq '.'

# Verificar espacio en disco
du -sh logs/

# Validar formato JSON
cat logs/app.log | jq empty
```

---

**Versión del Sistema**: 1.0.0  
**Última Actualización**: 2024-01-15  
**Compatibilidad**: Node.js 18+, PostgreSQL 12+, TypeScript 5+