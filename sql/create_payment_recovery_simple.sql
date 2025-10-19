-- Crear tabla de logs de recuperación de pagos
CREATE TABLE payment_recovery_logs (
    id SERIAL PRIMARY KEY,
    payment_id INTEGER NOT NULL,
    step VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL,
    data TEXT DEFAULT '{}',
    error TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX idx_payment_recovery_payment_id ON payment_recovery_logs(payment_id);
CREATE INDEX idx_payment_recovery_timestamp ON payment_recovery_logs(timestamp);

-- Agregar campos de recovery a payments
ALTER TABLE payments ADD COLUMN recovery_attempts INTEGER DEFAULT 0;
ALTER TABLE payments ADD COLUMN last_recovery_at TIMESTAMP;
ALTER TABLE payments ADD COLUMN idempotency_key VARCHAR(255);