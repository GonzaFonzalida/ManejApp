"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const supertest_1 = __importDefault(require("supertest"));
const app_1 = require("../../src/app");
const prismaClient_1 = require("../../src/config/prismaClient");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const db_cleaner_1 = require("../helpers/db-cleaner");
const app = (0, app_1.buildApp)();
describe('Schedule Integration Tests', () => {
    beforeEach(async () => {
        await (0, db_cleaner_1.clearDatabase)();
    });
    afterAll(async () => {
        await prismaClient_1.prisma.$disconnect();
    });
    const createInstructor = async () => {
        const hashedPassword = await bcryptjs_1.default.hash('password123', 10);
        const user = await prismaClient_1.prisma.user.create({
            data: {
                name: 'Instructor',
                surname: 'One',
                email: 'instructor@example.com',
                dni: '12345678',
                password: hashedPassword,
                role: 'INSTRUCTOR',
                birthDate: new Date('1980-01-01')
            }
        });
        const instructor = await prismaClient_1.prisma.instructor.create({
            data: {
                userId: user.id,
                licenseNumber: 'LIC-12345',
                experienceYears: 5
            }
        });
        // Login to get token
        const loginRes = await (0, supertest_1.default)(app).post('/api/v1/auth/login').send({
            email: 'instructor@example.com',
            password: 'password123'
        });
        return { user, instructor, token: loginRes.body.accessToken };
    };
    const createStudent = async () => {
        const hashedPassword = await bcryptjs_1.default.hash('password123', 10);
        const user = await prismaClient_1.prisma.user.create({
            data: {
                name: 'Student',
                surname: 'One',
                email: 'student@example.com',
                dni: '87654321',
                password: hashedPassword,
                role: 'STUDENT',
                birthDate: new Date('2000-01-01')
            }
        });
        await prismaClient_1.prisma.student.create({ data: { userId: user.id } });
        const loginRes = await (0, supertest_1.default)(app).post('/api/v1/auth/login').send({
            email: 'student@example.com',
            password: 'password123'
        });
        return { user, token: loginRes.body.accessToken };
    };
    describe('POST /api/v1/schedule/slots', () => {
        it('should allow instructor to create a slot', async () => {
            const { token } = await createInstructor();
            const startTime = new Date();
            startTime.setHours(startTime.getHours() + 24); // Tomorrow
            const endTime = new Date(startTime);
            endTime.setHours(startTime.getHours() + 1);
            const response = await (0, supertest_1.default)(app)
                .post('/api/v1/schedule/slots')
                .set('Authorization', `Bearer ${token}`)
                .send({
                startTime: startTime.toISOString(),
                endTime: endTime.toISOString()
            });
            expect(response.status).toBe(201);
            expect(response.body).toHaveProperty('id');
            expect(response.body.status).toBe('AVAILABLE');
        });
        it('should fail when creating an overlapping slot', async () => {
            const { token } = await createInstructor();
            const startTime = new Date();
            startTime.setHours(startTime.getHours() + 25); // overlaps with previous test's "Tomorrow" if strictly same time, but here new user
            // Let's make sure we have an existing slot for *this* instructor
            const endTime = new Date(startTime);
            endTime.setHours(startTime.getHours() + 2);
            // Create first slot
            await (0, supertest_1.default)(app)
                .post('/api/v1/schedule/slots')
                .set('Authorization', `Bearer ${token}`)
                .send({
                startTime: startTime.toISOString(),
                endTime: endTime.toISOString()
            });
            // Try create overlapping slot (starts 1 hour after, so overlaps by 1 hour)
            const overlapStart = new Date(startTime);
            overlapStart.setHours(overlapStart.getHours() + 1);
            const overlapEnd = new Date(overlapStart);
            overlapEnd.setHours(overlapStart.getHours() + 2);
            const response = await (0, supertest_1.default)(app)
                .post('/api/v1/schedule/slots')
                .set('Authorization', `Bearer ${token}`)
                .send({
                startTime: overlapStart.toISOString(),
                endTime: overlapEnd.toISOString()
            });
            expect(response.status).toBe(409);
        });
    });
    describe('POST /api/v1/schedule/reserve/:slotId', () => {
        it('should allow student to reserve an available slot', async () => {
            const { instructor } = await createInstructor();
            const { token: studentToken } = await createStudent();
            // Create slot directly in DB for setup
            const startTime = new Date();
            startTime.setDate(startTime.getDate() + 1);
            const endTime = new Date(startTime);
            endTime.setHours(startTime.getHours() + 1);
            const slot = await prismaClient_1.prisma.scheduleSlot.create({
                data: {
                    instructorId: instructor.id,
                    startTime,
                    endTime,
                    status: 'AVAILABLE'
                }
            });
            const response = await (0, supertest_1.default)(app)
                .post(`/api/v1/schedule/reserve/${slot.id}`)
                .set('Authorization', `Bearer ${studentToken}`);
            expect(response.status).toBe(201);
            expect(response.body.slot.status).toBe('HELD');
        });
    });
});
