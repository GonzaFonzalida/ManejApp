"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const supertest_1 = __importDefault(require("supertest"));
const app_1 = require("../../src/app");
const prismaClient_1 = require("../../src/config/prismaClient");
const db_cleaner_1 = require("../helpers/db-cleaner");
const app = (0, app_1.buildApp)();
describe('User Integration Tests', () => {
    beforeEach(async () => {
        await (0, db_cleaner_1.clearDatabase)();
    });
    afterAll(async () => {
        await prismaClient_1.prisma.$disconnect();
    });
    describe('POST /api/v1/users/register', () => {
        it('should register a new student', async () => {
            const userData = {
                name: 'John',
                surname: 'Doe',
                email: 'john.doe@example.com',
                dni: '87654321',
                password: 'securePassword123!',
                birthDate: '1995-05-15',
                phoneNumber: '1234567890'
            };
            const response = await (0, supertest_1.default)(app)
                .post('/api/v1/users/register')
                .send(userData);
            expect(response.status).toBe(201);
            expect(response.body).toHaveProperty('token'); // The response structure returns { token: userObject }
            expect(response.body.token).toHaveProperty('id');
            expect(response.body.token.email).toBe(userData.email);
            // Verify DB
            const userInDb = await prismaClient_1.prisma.user.findUnique({ where: { email: userData.email } });
            expect(userInDb).toBeDefined();
            expect(userInDb?.role).toBe('STUDENT');
        });
        it('should fail with duplicate email', async () => {
            const userData = {
                name: 'Jane',
                surname: 'Doe',
                email: 'jane.doe@example.com',
                dni: '11223344',
                password: 'securePassword123!',
                birthDate: '1995-05-15'
            };
            await (0, supertest_1.default)(app).post('/api/v1/users/register').send(userData);
            const response = await (0, supertest_1.default)(app)
                .post('/api/v1/users/register')
                .send({ ...userData, dni: '99887766' }); // Different DNI, same email
            expect(response.status).toBe(409);
        });
    });
    describe('GET /api/v1/users', () => {
        it('should fail without authentication', async () => {
            const response = await (0, supertest_1.default)(app).get('/api/v1/users');
            // Assuming the middleware returns 401 or 403
            expect([401, 403]).toContain(response.status);
        });
    });
});
