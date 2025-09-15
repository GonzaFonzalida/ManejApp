#!/usr/bin/env node

/**
 * Script de Configuración del Sistema de Logging
 * 
 * Este script automatiza la configuración inicial del sistema de logging
 * para ManejApp, incluyendo la creación de directorios y tabla de base de datos.
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('🚀 Configurando Sistema de Logging para ManejApp...\n');

// 1. Crear directorio de logs
const logsDir = path.join(__dirname, '..', 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
  console.log('✅ Directorio de logs creado:', logsDir);
} else {
  console.log('ℹ️  Directorio de logs ya existe:', logsDir);
}

// 2. Verificar archivo .env
const envPath = path.join(__dirname, '..', '.env');
const envExamplePath = path.join(__dirname, '..', '.env.example');

if (!fs.existsSync(envPath)) {
  if (fs.existsSync(envExamplePath)) {
    fs.copyFileSync(envExamplePath, envPath);
    console.log('✅ Archivo .env creado desde .env.example');
    console.log('⚠️  IMPORTANTE: Configura las variables de entorno en .env');
  } else {
    console.log('❌ No se encontró .env.example para copiar');
  }
} else {
  console.log('ℹ️  Archivo .env ya existe');
}

// 3. Verificar configuración de logging en .env
const envContent = fs.readFileSync(envPath, 'utf8');
const requiredLogVars = [
  'LOG_LEVEL',
  'ENABLE_CONSOLE_LOGS',
  'ENABLE_FILE_LOGS',
  'ENABLE_DATABASE_LOGS',
  'LOG_DIRECTORY',
  'LOG_FILENAME',
  'LOG_MAX_SIZE',
  'LOG_MAX_FILES',
  'LOG_TABLE_NAME',
  'LOG_RETENTION_DAYS'
];

const missingVars = requiredLogVars.filter(varName => !envContent.includes(varName));

if (missingVars.length > 0) {
  console.log('⚠️  Variables de logging faltantes en .env:');
  missingVars.forEach(varName => console.log(`   - ${varName}`));
  console.log('   Agrega estas variables desde .env.example\n');
} else {
  console.log('✅ Todas las variables de logging están configuradas\n');
}

// 4. Instrucciones para la tabla de base de datos
console.log('📋 PRÓXIMOS PASOS:\n');

console.log('1. 🗄️  Configurar tabla de logs en base de datos:');
console.log('   Ejecuta el siguiente comando en tu base de datos PostgreSQL:');
console.log('   psql -d tu_base_de_datos -f sql/create_logs_table.sql\n');

console.log('2. 🔧 Verificar configuración:');
console.log('   - Revisa las variables en .env');
console.log('   - Ajusta LOG_LEVEL según tu ambiente');
console.log('   - Configura los transports necesarios\n');

console.log('3. 🧪 Probar el sistema:');
console.log('   npm run dev');
console.log('   El sistema de logging se inicializará automáticamente\n');

console.log('4. 📊 Monitorear logs:');
console.log('   - Consola: Logs en tiempo real durante desarrollo');
console.log('   - Archivos: tail -f logs/app.log');
console.log('   - Base de datos: SELECT * FROM logs ORDER BY timestamp DESC LIMIT 10;\n');

console.log('✨ Sistema de logging configurado exitosamente!');
console.log('📖 Para más información, consulta README-LOGGING.md');