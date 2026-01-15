const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function createAdminUser() {
  try {
    // Verificar si ya existe el admin
    const existingAdmin = await prisma.user.findUnique({
      where: { email: 'admin@gmail.com' }
    });

    if (existingAdmin) {
      console.log('Usuario admin ya existe');
      return;
    }

    // Hash de la contraseña
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('Admin123!', salt);

    // Crear usuario admin en transacción
    const admin = await prisma.$transaction(async (tx) => {
      // Crear usuario
      const user = await tx.user.create({
        data: {
          name: 'Admin',
          surname: 'System',
          email: 'admin@gmail.com',
          dni: '00000000',
          password: hashedPassword,
          birthDate: new Date('1990-01-01'),
          role: 'ADMIN',
          isActive: true,
          emailVerifiedAt: new Date()
        }
      });

      // Crear registro Admin
      await tx.admin.create({
        data: {
          id: user.id,
          companyName: 'ManejApp'
        }
      });

      return user;
    });

    console.log('Usuario admin creado exitosamente:', {
      id: admin.id,
      email: admin.email,
      role: admin.role
    });

  } catch (error) {
    console.error('Error creando usuario admin:', error);
  } finally {
    await prisma.$disconnect();
  }
}

createAdminUser();