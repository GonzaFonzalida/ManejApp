const fs = require('fs');
const path = require('path');

// Mapeo de patrones de imports relativos a path aliases
const importMappings = {
  // Shared imports
  '../shared/': '@shared/',
  '../../shared/': '@shared/',
  '../../../shared/': '@shared/',
  '../shared/types/': '@sharedTypes/',
  '../../shared/types/': '@sharedTypes/',
  '../shared/classes/': '@classes/',
  '../../shared/classes/': '@classes/',
  '../shared/middlewares/': '@middlewares/',
  '../../shared/middlewares/': '@middlewares/',
  '../shared/utils/': '@utils/',
  '../../shared/utils/': '@utils/',
  '../shared/logging/': '@logging/',
  '../../shared/logging/': '@logging/',
  
  // Config imports
  '../config/': '@config/',
  '../../config/': '@config/',
  '../../../config/': '@config/',
  
  // Module imports
  '../users/': '@users/',
  '../../users/': '@users/',
  '../modules/users/': '@users/',
  '../../modules/users/': '@users/',
  '../modules/auth/': '@auth/',
  '../../modules/auth/': '@auth/',
  '../modules/cars/': '@cars/',
  '../../modules/cars/': '@cars/',
  '../modules/instructors/': '@instructors/',
  '../../modules/instructors/': '@instructors/',
  '../modules/permissions/': '@permissions/',
  '../../modules/permissions/': '@permissions/',
  '../modules/drivingClass/': '@drivingClass/',
  '../../modules/drivingClass/': '@drivingClass/',
  '../modules/payments/': '@payments/',
  '../../modules/payments/': '@payments/',
  '../modules/schedule/': '@schedule/',
  '../../modules/schedule/': '@schedule/',
  '../modules/notifications/': '@notifications/',
  '../../modules/notifications/': '@notifications/',
  
  // Specific patterns
  'src/modules/auth/': '@auth/',
  'src/modules/users/': '@users/',
  './users/': '@users/',
  './modules/': '@',
};

function updateImportsInFile(filePath) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    let updated = false;
    
    // Buscar y reemplazar imports
    for (const [oldPattern, newPattern] of Object.entries(importMappings)) {
      const regex = new RegExp(`(import.*?from\\s+["'])${oldPattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'g');
      if (regex.test(content)) {
        content = content.replace(regex, `$1${newPattern}`);
        updated = true;
      }
    }
    
    if (updated) {
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`✅ Updated: ${filePath}`);
      return true;
    }
    
    return false;
  } catch (error) {
    console.error(`❌ Error updating ${filePath}:`, error.message);
    return false;
  }
}

function processDirectory(dirPath) {
  const items = fs.readdirSync(dirPath);
  let totalUpdated = 0;
  
  for (const item of items) {
    const fullPath = path.join(dirPath, item);
    const stat = fs.statSync(fullPath);
    
    if (stat.isDirectory()) {
      // Recursivamente procesar subdirectorios
      totalUpdated += processDirectory(fullPath);
    } else if (item.endsWith('.ts') && !item.endsWith('.d.ts')) {
      // Procesar archivos TypeScript
      if (updateImportsInFile(fullPath)) {
        totalUpdated++;
      }
    }
  }
  
  return totalUpdated;
}

// Ejecutar el script
const srcPath = path.join(__dirname, '..', 'src');
console.log('🔄 Actualizando imports relativos a path aliases...');
console.log(`📁 Procesando directorio: ${srcPath}`);

const updatedFiles = processDirectory(srcPath);

console.log(`\n✨ Proceso completado!`);
console.log(`📊 Archivos actualizados: ${updatedFiles}`);