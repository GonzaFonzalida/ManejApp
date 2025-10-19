const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function setupPaymentRecovery() {
  try {
    console.log('Setting up payment recovery tables...');

    // Create payment_recovery_logs table
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS payment_recovery_logs (
        id SERIAL PRIMARY KEY,
        payment_id INTEGER NOT NULL,
        step VARCHAR(100) NOT NULL,
        status VARCHAR(20) NOT NULL,
        data TEXT DEFAULT '{}',
        error TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // Create indexes
    await prisma.$executeRaw`
      CREATE INDEX IF NOT EXISTS idx_payment_recovery_payment_id ON payment_recovery_logs(payment_id)
    `;

    await prisma.$executeRaw`
      CREATE INDEX IF NOT EXISTS idx_payment_recovery_timestamp ON payment_recovery_logs(timestamp)
    `;

    // Add recovery fields to payments table
    try {
      await prisma.$executeRaw`
        ALTER TABLE payments ADD COLUMN IF NOT EXISTS recovery_attempts INTEGER DEFAULT 0
      `;
    } catch (e) {
      console.log('recovery_attempts column already exists');
    }

    try {
      await prisma.$executeRaw`
        ALTER TABLE payments ADD COLUMN IF NOT EXISTS last_recovery_at TIMESTAMP
      `;
    } catch (e) {
      console.log('last_recovery_at column already exists');
    }

    try {
      await prisma.$executeRaw`
        ALTER TABLE payments ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(255)
      `;
    } catch (e) {
      console.log('idempotency_key column already exists');
    }

    // Create unique index for idempotency_key
    try {
      await prisma.$executeRaw`
        CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_idempotency ON payments(idempotency_key)
      `;
    } catch (e) {
      console.log('idempotency index already exists');
    }

    console.log('✅ Payment recovery setup completed successfully!');

  } catch (error) {
    console.error('❌ Error setting up payment recovery:', error);
  } finally {
    await prisma.$disconnect();
  }
}

setupPaymentRecovery();