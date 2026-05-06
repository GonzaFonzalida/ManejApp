/**
 * Asegura el usuario admin@manejapp.com con rol ADMIN y la contraseña de demo.
 * - Si existe: actualiza hash, activa cuenta y fila Admin si faltaba.
 * - Si no existe: crea usuario + registro Admin (DNI reservado demo).
 *
 * Uso (desde ManejApp/): node scripts/reset-admin-password.js
 */
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

const ADMIN_EMAIL = 'admin@manejapp.com';
const NEW_PASSWORD = '1qazxsw2';
/** DNI solo usado al crear el admin por primera vez (debe seguir siendo único en tu DB). */
const DEMO_ADMIN_DNI = '99999001';

async function resetAdminPassword() {
  try {
    let user = await prisma.user.findUnique({
      where: { email: ADMIN_EMAIL },
      include: { admin: true },
    });

    const hashedPassword = await bcrypt.hash(NEW_PASSWORD, 10);

    if (!user) {
      const existingDni = await prisma.user.findUnique({
        where: { dni: DEMO_ADMIN_DNI },
      });
      if (existingDni) {
        console.error(
          'Ya existe otro usuario con DNI',
          DEMO_ADMIN_DNI,
          '— borrálo o cambiá DEMO_ADMIN_DNI en scripts/reset-admin-password.js',
        );
        process.exit(1);
      }

      user = await prisma.user.create({
        data: {
          name: 'Admin',
          surname: 'ManejApp',
          email: ADMIN_EMAIL,
          password: hashedPassword,
          dni: DEMO_ADMIN_DNI,
          birthDate: new Date('1990-01-01'),
          role: 'ADMIN',
          isActive: true,
        },
        include: { admin: true },
      });

      await prisma.admin.create({
        data: { id: user.id, companyName: 'ManejApp' },
      });

      console.log('Usuario administrador creado.');
    } else {
      await prisma.user.update({
        where: { id: user.id },
        data: { password: hashedPassword, isActive: true },
      });

      if (!user.admin) {
        await prisma.admin.create({
          data: { id: user.id, companyName: 'ManejApp' },
        });
      }

      console.log('Contraseña actualizada correctamente.');
    }

    console.log('Email:', ADMIN_EMAIL);
    console.log('Contraseña (demo):', NEW_PASSWORD);
    console.log('Rol: ADMIN — usá estas credenciales en el login de manejapp-admin.');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

resetAdminPassword();
