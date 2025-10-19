const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function setupBlacklistedTokens() {
  try {
    console.log('Setting up blacklisted tokens table...');

    // Create blacklisted_tokens table
    await prisma.$executeRaw`
      CREATE TABLE IF NOT EXISTS blacklisted_tokens (
        id SERIAL PRIMARY KEY,
        jti VARCHAR(255) UNIQUE NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `;

    // Create indexes
    await prisma.$executeRaw`
      CREATE INDEX IF NOT EXISTS idx_blacklisted_tokens_jti ON blacklisted_tokens(jti)
    `;

    await prisma.$executeRaw`
      CREATE INDEX IF NOT EXISTS idx_blacklisted_tokens_expires_at ON blacklisted_tokens(expires_at)
    `;

    console.log('✅ Blacklisted tokens setup completed successfully!');

  } catch (error) {
    console.error('❌ Error setting up blacklisted tokens:', error);
  } finally {
    await prisma.$disconnect();
  }
}

setupBlacklistedTokens();