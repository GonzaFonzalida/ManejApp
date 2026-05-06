import request from 'supertest';
import { buildApp } from '../../src/app';
import { prisma } from '../../src/config/prismaClient';
import bcrypt from 'bcryptjs';
import { clearDatabase } from '../helpers/db-cleaner';

const app = buildApp();

describe('Schedule Integration Tests', () => {

    beforeEach(async () => {
        await clearDatabase();
    });

    afterAll(async () => {
        await prisma.$disconnect();
    });

    const createInstructor = async () => {
        const hashedPassword = await bcrypt.hash('password123', 10);
        const user = await prisma.user.create({
            data: {
                name: 'Instructor',
                surname: 'One',
                email: 'instructor@example.com',
                dni: '12345678',
                password: hashedPassword,
                role: 'INSTRUCTOR',
                birthDate: new Date('1980-01-01'),
                emailVerifiedAt: new Date(),
                isActive: true,
            }
        });
        const instructor = await prisma.instructor.create({
            data: {
                userId: user.id,
                licenseNumber: 'LIC-12345',
                experienceYears: 5
            }
        });

        // Login to get token
        const loginRes = await request(app).post('/api/v1/auth/login').send({
            email: 'instructor@example.com',
            password: 'password123'
        });
        return { user, instructor, token: loginRes.body.accessToken };
    };

    const createStudent = async () => {
        const hashedPassword = await bcrypt.hash('password123', 10);
        const user = await prisma.user.create({
            data: {
                name: 'Student',
                surname: 'One',
                email: 'student@example.com',
                dni: '87654321',
                password: hashedPassword,
                role: 'STUDENT',
                birthDate: new Date('2000-01-01'),
                emailVerifiedAt: new Date(),
                isActive: true,
            }
        });
        await prisma.student.create({ data: { userId: user.id } });

        const loginRes = await request(app).post('/api/v1/auth/login').send({
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

            const response = await request(app)
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
            await request(app)
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

            const response = await request(app)
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

            const slot = await prisma.scheduleSlot.create({
                data: {
                    instructorId: instructor.id,
                    startTime,
                    endTime,
                    status: 'AVAILABLE'
                }
            });

            const response = await request(app)
                .post(`/api/v1/schedule/reserve/${slot.id}`)
                .set('Authorization', `Bearer ${studentToken}`);

            expect(response.status).toBe(201);
            expect(response.body.slot.status).toBe('HELD');
        });
    });

    describe('GET /api/v1/schedule/preview/:slotId', () => {
        it('should return premium preview data for student', async () => {
            const { instructor } = await createInstructor();
            const { token: studentToken } = await createStudent();

            const startTime = new Date();
            startTime.setDate(startTime.getDate() + 2);
            const endTime = new Date(startTime);
            endTime.setMinutes(startTime.getMinutes() + 90);

            const slot = await prisma.scheduleSlot.create({
                data: {
                    instructorId: instructor.id,
                    startTime,
                    endTime,
                    status: 'AVAILABLE',
                }
            });

            const response = await request(app)
                .get(`/api/v1/schedule/preview/${slot.id}`)
                .set('Authorization', `Bearer ${studentToken}`);

            expect(response.status).toBe(200);
            expect(response.body).toEqual(
                expect.objectContaining({
                    slotId: slot.id,
                    canReserveNow: true,
                    durationMinutes: 90,
                    startsAt: expect.any(String),
                    endsAt: expect.any(String),
                    policySummary: expect.objectContaining({
                        cancelWindowHours: 6,
                        rescheduleWindowHours: 12,
                    }),
                    priceSummary: expect.objectContaining({
                        amount: expect.any(Number),
                        currency: 'ARS',
                    }),
                    instructorSnapshot: expect.objectContaining({
                        id: instructor.id,
                    }),
                })
            );
        });
    });
});
