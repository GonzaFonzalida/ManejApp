-- Tabla para logging de recuperación de pagos
CREATE TABLE IF NOT EXISTS payment_recovery_logs (
    id SERIAL PRIMARY KEY,
    payment_id INTEGER NOT NULL,
    step VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('started', 'completed', 'failed')),
    data JSONB DEFAULT '{}',
    error TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices por separado
CREATE INDEX IF NOT EXISTS idx_payment_recovery_payment_id ON payment_recovery_logs(payment_id);
CREATE INDEX IF NOT EXISTS idx_payment_recovery_timestamp ON payment_recovery_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_payment_recovery_status ON payment_recovery_logs(status);

-- Agregar campos de recovery a la tabla payments
ALTER TABLE payments 
ADD COLUMN IF NOT EXISTS recovery_attempts INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_recovery_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(255) UNIQUE;

-- Función para limpiar logs antiguos (más de 30 días)
CREATE OR REPLACE FUNCTION cleanup_old_payment_recovery_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM payment_recovery_logs 
    WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Función para detectar pagos stuck
CREATE OR REPLACE FUNCTION find_stuck_payments()
RETURNS TABLE(
    payment_id INTEGER,
    status VARCHAR(50),
    stuck_duration INTERVAL,
    last_step VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.status,
        NOW() - p.updated_at as stuck_duration,
        prl.step
    FROM payments p
    LEFT JOIN LATERAL (
        SELECT step 
        FROM payment_recovery_logs 
        WHERE payment_id = p.id 
        ORDER BY timestamp DESC 
        LIMIT 1
    ) prl ON true
    WHERE p.status IN ('processing', 'pending')
    AND p.updated_at < NOW() - INTERVAL '10 minutes';
END;
$$ LANGUAGE plpgsql;