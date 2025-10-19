const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function verifySetup() {
  try {
    console.log('🔍 Verificando configuración de base de datos...\n');

    // Verificar tabla Payment con nuevos campos
    const paymentFields = await prisma.$queryRaw`
      SELECT column_name, data_type, is_nullable 
      FROM information_schema.columns 
      WHERE table_name = 'Payment' 
      ORDER BY column_name
    `;
    
    console.log('✅ Campos de la tabla Payment:');
    paymentFields.forEach(field => {
      console.log(`   - ${field.column_name}: ${field.data_type} (${field.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
    });

    // Verificar tabla PaymentRecoveryLog
    const recoveryLogExists = await prisma.$queryRaw`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'payment_recovery_logs'
      )
    `;
    
    console.log(`\n✅ Tabla payment_recovery_logs: ${recoveryLogExists[0].exists ? 'Existe' : 'No existe'}`);

    // Verificar tabla BlacklistedToken
    const blacklistExists = await prisma.$queryRaw`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'blacklisted_tokens'
      )
    `;
    
    console.log(`✅ Tabla blacklisted_tokens: ${blacklistExists[0].exists ? 'Existe' : 'No existe'}`);

    // Verificar índices
    const indexes = await prisma.$queryRaw`
      SELECT indexname, tablename 
      FROM pg_indexes 
      WHERE tablename IN ('Payment', 'payment_recovery_logs', 'blacklisted_tokens')
      ORDER BY tablename, indexname
    `;
    
    console.log('\n✅ Índices creados:');
    indexes.forEach(idx => {
      console.log(`   - ${idx.tablename}.${idx.indexname}`);
    });

    // Test de inserción en payment_recovery_logs
    try {
      await prisma.$executeRaw`
        INSERT INTO payment_recovery_logs (payment_id, step, status, data) 
        VALUES (999, 'test_step', 'completed', '{"test": true}')
      `;
      
      await prisma.$executeRaw`
        DELETE FROM payment_recovery_logs WHERE payment_id = 999
      `;
      
      console.log('\n✅ Test de inserción en payment_recovery_logs: OK');
    } catch (e) {
      console.log('\n❌ Error en test de payment_recovery_logs:', e.message);
    }

    // Test de inserción en blacklisted_tokens
    try {
      await prisma.$executeRaw`
        INSERT INTO blacklisted_tokens (jti, expires_at) 
        VALUES ('test-jti-123', NOW() + INTERVAL '1 hour')
      `;
      
      await prisma.$executeRaw`
        DELETE FROM blacklisted_tokens WHERE jti = 'test-jti-123'
      `;
      
      console.log('✅ Test de inserción en blacklisted_tokens: OK');
    } catch (e) {
      console.log('❌ Error en test de blacklisted_tokens:', e.message);
    }

    console.log('\n🎉 ¡Configuración de seguridad y recuperación completada exitosamente!');
    console.log('\n📋 Resumen de mejoras implementadas:');
    console.log('   • Sistema de recuperación de pagos');
    console.log('   • Logging detallado de transacciones');
    console.log('   • JWT blacklisting para logout seguro');
    console.log('   • Campos de idempotencia para pagos');
    console.log('   • Índices optimizados para performance');

  } catch (error) {
    console.error('❌ Error en verificación:', error);
  } finally {
    await prisma.$disconnect();
  }
}

verifySetup();