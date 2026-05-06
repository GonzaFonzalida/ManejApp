"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const bcrypt = __importStar(require("bcryptjs"));
const prisma = new client_1.PrismaClient();
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
