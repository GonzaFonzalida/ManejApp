-- =============================================================================
-- Migración: Crear tabla de logs para el sistema de logging
-- Descripción: Tabla optimizada para almacenar logs de aplicación con índices
-- Fecha: 2024-01-15
-- =============================================================================

-- Crear tabla de logs
CREATE TABLE IF NOT EXISTS logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    level VARCHAR(10) NOT NULL CHECK (level IN ('error', 'warn', 'info', 'debug')),
    message TEXT NOT NULL,
    context JSONB,
    error JSONB,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Crear índices para optimizar consultas frecuentes
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at);

-- Índices para consultas por contexto (usando expresiones JSONB)
CREATE INDEX IF NOT EXISTS idx_logs_request_id ON logs((context->>'requestId'));
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON logs((context->>'userId'));
CREATE INDEX IF NOT EXISTS idx_logs_module ON logs((context->>'module'));

-- Índice compuesto para consultas de análisis temporal
CREATE INDEX IF NOT EXISTS idx_logs_level_timestamp ON logs(level, timestamp);

-- Comentarios para documentación
COMMENT ON TABLE logs IS 'Tabla de logs del sistema ManejApp';
COMMENT ON COLUMN logs.timestamp IS 'Timestamp del evento loggeado';
COMMENT ON COLUMN logs.level IS 'Nivel de severidad: error, warn, info, debug';
COMMENT ON COLUMN logs.message IS 'Mensaje descriptivo del evento';
COMMENT ON COLUMN logs.context IS 'Contexto del request y aplicación en formato JSON';
COMMENT ON COLUMN logs.error IS 'Información detallada del error en formato JSON';
COMMENT ON COLUMN logs.metadata IS 'Datos adicionales del evento en formato JSON';
COMMENT ON COLUMN logs.created_at IS 'Timestamp de inserción en la base de datos';

-- =============================================================================
-- Consultas de ejemplo para verificar la instalación:
-- =============================================================================

-- Verificar que la tabla se creó correctamente
-- SELECT table_name, column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_name = 'logs' 
-- ORDER BY ordinal_position;

-- Verificar índices creados
-- SELECT indexname, indexdef 
-- FROM pg_indexes 
-- WHERE tablename = 'logs';

-- Insertar log de prueba
-- INSERT INTO logs (timestamp, level, message, context) 
-- VALUES (NOW(), 'info', 'Sistema de logging instalado correctamente', '{"module": "setup"}');

-- =============================================================================
-- Consultas de mantenimiento:
-- =============================================================================

-- Limpiar logs antiguos (ejecutar periódicamente)
-- DELETE FROM logs WHERE created_at < NOW() - INTERVAL '30 days';

-- Analizar uso de espacio de la tabla
-- SELECT 
--   pg_size_pretty(pg_total_relation_size('logs')) as total_size,
--   pg_size_pretty(pg_relation_size('logs')) as table_size,
--   pg_size_pretty(pg_total_relation_size('logs') - pg_relation_size('logs')) as index_size;

-- Estadísticas de logs por nivel
-- SELECT level, COUNT(*) as count, 
--        MIN(timestamp) as oldest, 
--        MAX(timestamp) as newest
-- FROM logs 
-- GROUP BY level 
-- ORDER BY count DESC;