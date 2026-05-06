import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
    console.log('🗑️  Limpiando TODOS los datos de prueba...');

    // 1. Delete all payments first (depend on DrivingClass)
    await prisma.payment.deleteMany({});

    // 2. Delete all schedule slots (depend on Instructor)
    await prisma.scheduleSlot.deleteMany({});

    // 3. Delete all DrivingClasses (depend on Instructor and Student)
    await prisma.drivingClass.deleteMany({});

    // 4. Delete all Cars
    await prisma.car.deleteMany({});

    // 5. Delete Instructor Permissions
    await prisma.instructorPermission.deleteMany({});

    // 6. Delete Instructors
    await prisma.instructor.deleteMany({});

    // 7. Delete Students profiles
    await prisma.student.deleteMany({});

    // 8. Delete Users (only those that are not ADMIN ideally, but for now lets wipe non-admin)
    await prisma.user.deleteMany({
        where: { role: { not: 'ADMIN' } }
    });

    console.log('✅ Base de datos limpia (excepto admins).');

    console.log('👤 Creando Instructor Demo "Carlos"...');

    const password = await bcrypt.hash('123456', 10);

    const profileImage = 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=687&q=80';

    const demoUser = await prisma.user.create({
        data: {
            email: 'instructor_demo@test.com',
            password,
            name: 'Carlos',
            surname: 'Rodriguez',
            dni: '20123456',
            birthDate: new Date('1985-05-15'),
            role: 'INSTRUCTOR',
            isActive: true, // Auto-activate
            profileImage: profileImage,
            location: 'Av. Libertador 2000, Buenos Aires',
            instructor: {
                create: {
                    licenseNumber: 'A12345678',
                    experienceYears: 12,
                    available: true,
                    isValid: true,
                    bio: 'Más de 10 años formando conductores seguros en la ciudad. Experto en estacionamiento y maniobras complejas. Mi objetivo es que pierdas el miedo y disfrutes manejar.',
                    hourlyRate: 15000,
                    isListed: true,
                    commissionRate: 80,
                    cars: {
                        create: {
                            brand: 'Toyota',
                            model: 'Etios Sedán',
                            year: 2022,
                            licensePlate: 'AD 123 OP',
                            transmission: 'MANUAL',
                            isActive: true,
                        }
                    }
                }
            }
        },
        include: {
            instructor: true
        }
    });

    // Re-create Student for testing
    await prisma.user.create({
        data: {
            email: 'student@test.com',
            password,
            name: 'Maria',
            surname: 'Gomez',
            dni: '30123456',
            birthDate: new Date('2000-01-01'),
            role: 'STUDENT',
            isActive: true,
            student: { create: {} }
        }
    });

    const instructorId = demoUser.instructor?.id;
    if (!instructorId) throw new Error('Falló la creación del instructor');

    console.log(`✅ Instructor Carlos creado con éxito.`);
    console.log('📅 Generando horarios...');

    const today = new Date();
    const slots = [];

    // Next 5 days
    for (let i = 0; i < 5; i++) {
        const date = new Date(today);
        date.setDate(today.getDate() + i);

        const times = ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00'];

        for (const timeStr of times) {
            const [h, m] = timeStr.split(':');
            const start = new Date(date);
            start.setHours(parseInt(h), parseInt(m), 0, 0);

            const end = new Date(start);
            end.setHours(start.getHours() + 1);

            await prisma.scheduleSlot.create({
                data: {
                    instructorId: instructorId,
                    startTime: start,
                    endTime: end,
                    status: 'AVAILABLE'
                }
            });
        }
    }

    console.log(`✅ Horarios generados.`);
    console.log('🎉 Listo. Puedes probar la app.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
