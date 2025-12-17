const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function createAdmin() {
  try {
    // Obtener argumentos de la línea de comandos
    const args = process.argv.slice(2);
    if (args.length < 7) {
      console.log('Uso: node scripts/create-admin.js <name> <surname> <email> <password> <dni> <birthDate> <companyName>');
      console.log('Ejemplo: node scripts/create-admin.js "Admin" "User" admin@example.com password123 12345678 "1990-01-01" "Mi Compañía"');
      process.exit(1);
    }

    const [name, surname, email, password, dni, birthDateStr, companyName] = args;
    const birthDate = new Date(birthDateStr);

    if (isNaN(birthDate.getTime())) {
      throw new Error('Fecha de nacimiento inválida. Use formato YYYY-MM-DD');
    }

    console.log('Creando usuario administrador...');

    // Hashear la contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear el usuario con rol ADMIN
    const user = await prisma.user.create({
      data: {
        name,
        surname,
        email,
        password: hashedPassword,
        dni,
        birthDate,
        role: 'ADMIN',
        isActive: true,
      },
    });

    // Crear la entrada en Admin
    await prisma.admin.create({
      data: {
        id: user.id,
        companyName,
      },
    });

    console.log('✅ Usuario administrador creado exitosamente!');
    console.log(`ID: ${user.id}`);
    console.log(`Email: ${user.email}`);
    console.log(`Rol: ${user.role}`);
    console.log(`Compañía: ${companyName}`);

  } catch (error) {
    console.error('❌ Error creando usuario administrador:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

createAdmin();