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
describe('Auth Integration Tests', () => {
    beforeAll(async () => {
        // Connect to DB if needed, though prisma client connects lazily
    });
    afterAll(async () => {
        // Cleanup
        await prismaClient_1.prisma.$disconnect();
    });
    beforeEach(async () => {
        await (0, db_cleaner_1.clearDatabase)();
    });
    describe('POST /api/v1/auth/login', () => {
        it('should login successfully with valid credentials', async () => {
            // Seed user
            const hashedPassword = await bcryptjs_1.default.hash('password123', 10);
            await prismaClient_1.prisma.user.create({
                data: {
                    name: 'Test',
                    surname: 'User',
                    email: 'test@example.com',
                    dni: '12345678',
                    password: hashedPassword,
                    role: 'STUDENT',
                    birthDate: new Date('2000-01-01'),
                    emailVerifiedAt: new Date()
                }
            });
            const response = await (0, supertest_1.default)(app)
                .post('/api/v1/auth/login')
                .send({
                email: 'test@example.com',
                password: 'password123'
            });
            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('accessToken');
            // Refresh token is in cookie, not body
            const cookies = response.headers['set-cookie'];
            expect(cookies).toBeDefined();
            expect(cookies.some((c) => c.includes('refreshToken'))).toBe(true);
            expect(response.body).toHaveProperty('user');
            expect(response.body.user.email).toBe('test@example.com');
        });
        it('should fail with invalid credentials', async () => {
            // Seed user
            const hashedPassword = await bcryptjs_1.default.hash('password123', 10);
            await prismaClient_1.prisma.user.create({
                data: {
                    name: 'Test',
                    surname: 'User',
                    email: 'test@example.com',
                    dni: '12345678',
                    password: hashedPassword,
                    role: 'STUDENT',
                    birthDate: new Date('2000-01-01'),
                    emailVerifiedAt: new Date()
                }
            });
            const response = await (0, supertest_1.default)(app)
                .post('/api/v1/auth/login')
                .send({
                email: 'test@example.com',
                password: 'wrongpassword'
            });
            expect(response.status).toBe(401);
        });
    });
});
