
import request from 'supertest';
import { buildApp } from '../src/app';
import { prisma } from '../src/config/prismaClient';
import bcrypt from 'bcryptjs';

const app = buildApp();

async function main() {
    // 1. Create Instructor
    const email = `inst-${Date.now()}@test.com`;
    const password = 'password123';
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
        data: {
            name: 'Inst',
            surname: 'Test',
            email,
            dni: Math.random().toString().slice(2, 10),
            password: hashedPassword,
            role: 'INSTRUCTOR',
            birthDate: new Date('1990-01-01')
        }
    });

    await prisma.instructor.create({
        data: {
            userId: user.id,
            licenseNumber: 'LIC-' + Date.now(),
            experienceYears: 5
        }
    });

    // 2. Login
    const loginRes = await request(app).post('/api/v1/auth/login').send({
        email,
        password
    });
    const token = loginRes.body.accessToken;
    console.log('Login successful, token:', token ? 'Yes' : 'No');

    // 3. Try to create slot with various date formats
    const scenarios = [
        { label: 'ISO String (JS generic)', startTime: new Date().toISOString(), endTime: new Date(Date.now() + 3600000).toISOString() },
        { label: 'Dart-like Microseconds', startTime: '2026-02-11T12:00:00.123456Z', endTime: '2026-02-11T13:00:00.123456Z' },
        { label: 'ISO without Z', startTime: '2026-02-11T12:00:00.123', endTime: '2026-02-11T13:00:00.123' },
        { label: 'No Milliseconds', startTime: '2026-02-11T12:00:00Z', endTime: '2026-02-11T13:00:00Z' },
        { label: 'Local String', startTime: '2023-12-25 10:00:00', endTime: '2023-12-25 11:00:00' },
        { label: 'Invalid Date', startTime: 'invalid-date', endTime: 'invalid-date' },
        { label: 'Empty', startTime: '', endTime: '' }
    ];

    for (const s of scenarios) {
        console.log(`\nTesting: ${s.label}`);
        const res = await request(app)
            .post('/api/v1/schedule/slots')
            .set('Authorization', `Bearer ${token}`)
            .send({
                startTime: s.startTime,
                endTime: s.endTime
            });

        console.log(`Status: ${res.status}`);
        console.log('Body:', JSON.stringify(res.body, null, 2));
    }
}

main().catch(console.error).finally(() => prisma.$disconnect());
