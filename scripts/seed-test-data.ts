import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
    const password = await bcrypt.hash('123456', 10);

    // Create Instructor User
    const instructorUser = await prisma.user.upsert({
        where: { email: 'instructor@test.com' },
        update: { password }, // Update password if exists
        create: {
            email: 'instructor@test.com',
            password,
            name: 'Juan',
            surname: 'Instructor',
            dni: '11111111',
            birthDate: new Date('1990-01-01'),
            role: 'INSTRUCTOR',
            isActive: true,
            instructor: {
                create: {
                    licenseNumber: 'L123456',
                    experienceYears: 5,
                    available: true,
                    isValid: true,
                }
            }
        },
        include: { instructor: true }
    });
    console.log('Instructor created/updated:', instructorUser.email);

    if (!instructorUser.instructor) {
        const existingInstructor = await prisma.instructor.findUnique({ where: { userId: instructorUser.id } });
        if (!existingInstructor) {
            await prisma.instructor.create({
                data: {
                    userId: instructorUser.id,
                    licenseNumber: 'L123456',
                    experienceYears: 5,
                    isValid: true,
                    available: true
                }
            });
            console.log('Instructor profile created for existing user');
        }
    }

    // Create Student User
    const studentUser = await prisma.user.upsert({
        where: { email: 'student@test.com' },
        update: { password }, // Update password if exists
        create: {
            email: 'student@test.com',
            password,
            name: 'Maria',
            surname: 'Estudiante',
            dni: '22222222',
            birthDate: new Date('2000-01-01'),
            role: 'STUDENT',
            isActive: true,
            student: {
                create: {}
            }
        },
        include: { student: true }
    });
    console.log('Student created/updated:', studentUser.email);

    if (!studentUser.student) {
        const existingStudent = await prisma.student.findUnique({ where: { userId: studentUser.id } });
        if (!existingStudent) {
            await prisma.student.create({
                data: {
                    userId: studentUser.id,
                }
            });
            console.log('Student profile created for existing user');
        }
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
