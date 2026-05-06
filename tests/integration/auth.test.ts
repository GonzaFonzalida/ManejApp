import request from 'supertest';
import { buildApp } from '../../src/app';
import { prisma } from '../../src/config/prismaClient';
import { Role } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { clearDatabase } from '../helpers/db-cleaner';

const app = buildApp();

function extractCookie(headers: any, name: string): string | undefined {
    const cookies = headers['set-cookie'] as unknown as string[] | undefined;
    if (!cookies) return undefined;
    const match = cookies.find((c: string) => c.startsWith(`${name}=`));
    if (!match) return undefined;
    return match.split(';')[0].split('=').slice(1).join('=');
}

async function seedUser(overrides: Partial<{ email: string; password: string; role: Role }> = {}) {
    const email = overrides.email ?? 'test@example.com';
    const password = overrides.password ?? 'password123';
    const role = overrides.role ?? Role.STUDENT;
    const hashedPassword = await bcrypt.hash(password, 10);
    return prisma.user.create({
        data: {
            name: 'Test',
            surname: 'User',
            email,
            dni: `${Date.now()}`,
            password: hashedPassword,
            role,
            birthDate: new Date('2000-01-01'),
            emailVerifiedAt: new Date(),
            isActive: true,
        },
    });
}

describe('Auth Integration Tests', () => {

    afterAll(async () => {
        await prisma.$disconnect();
    });

    beforeEach(async () => {
        await clearDatabase();
    });

    // ─── LOGIN CONTRACT ────────────────────────────────────────

    describe('POST /api/v1/auth/login', () => {
        it('should return accessToken, refreshToken, user, and session in body', async () => {
            await seedUser();

            const res = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            expect(res.status).toBe(200);

            // Body contract
            expect(res.body).toHaveProperty('accessToken');
            expect(typeof res.body.accessToken).toBe('string');
            expect(res.body).toHaveProperty('refreshToken');
            expect(typeof res.body.refreshToken).toBe('string');
            expect(res.body).toHaveProperty('user');
            expect(res.body.user.email).toBe('test@example.com');
            expect(res.body.user).not.toHaveProperty('password');
            expect(res.body).toHaveProperty('session');
            expect(res.body.session).toHaveProperty('id');
            expect(res.body.session).toHaveProperty('createdAt');
            expect(res.body.session).toHaveProperty('expiresAt');

            // Cookie still set for web clients
            const cookies = res.headers['set-cookie'] as unknown as string[];
            expect(cookies).toBeDefined();
            expect(cookies.some((c: string) => c.includes('refreshToken'))).toBe(true);
        });

        it('should fail with wrong password', async () => {
            await seedUser();

            const res = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'wrongpassword' });

            expect(res.status).toBe(401);
        });

        it('should fail with non-existent email', async () => {
            const res = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'nobody@example.com', password: 'password123' });

            expect(res.status).toBe(401);
        });
    });

    // ─── REFRESH CONTRACT ──────────────────────────────────────

    describe('POST /api/v1/auth/refresh', () => {
        it('should refresh using body refreshToken (mobile flow)', async () => {
            await seedUser();

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            const { refreshToken } = loginRes.body;
            expect(refreshToken).toBeDefined();

            const refreshRes = await request(app)
                .post('/api/v1/auth/refresh')
                .send({ refreshToken });

            expect(refreshRes.status).toBe(200);
            expect(refreshRes.body).toHaveProperty('accessToken');
            expect(typeof refreshRes.body.accessToken).toBe('string');
            expect(refreshRes.body).toHaveProperty('refreshToken');
            expect(typeof refreshRes.body.refreshToken).toBe('string');
            expect(refreshRes.body).toHaveProperty('session');
            expect(refreshRes.body.session).toHaveProperty('id');

            // New refresh token is different (rotation)
            expect(refreshRes.body.refreshToken).not.toBe(refreshToken);
        });

        it('should refresh using cookie (web flow)', async () => {
            await seedUser();

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            const cookieRefresh = extractCookie(loginRes.headers, 'refreshToken');
            expect(cookieRefresh).toBeDefined();

            const refreshRes = await request(app)
                .post('/api/v1/auth/refresh')
                .set('Cookie', `refreshToken=${cookieRefresh}`);

            expect(refreshRes.status).toBe(200);
            expect(refreshRes.body).toHaveProperty('accessToken');
            expect(refreshRes.body).toHaveProperty('refreshToken');
        });

        it('should fail with no token at all', async () => {
            const res = await request(app)
                .post('/api/v1/auth/refresh')
                .send({});

            expect(res.status).toBe(500);
        });

        it('should fail with an already-rotated (revoked) token', async () => {
            const user = await seedUser();

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            const { refreshToken: oldToken, session: loginSession } = loginRes.body;

            // First refresh: rotates the token
            const first = await request(app)
                .post('/api/v1/auth/refresh')
                .send({ refreshToken: oldToken });
            expect(first.status).toBe(200);

            // Verify the login session is revoked in DB
            const revokedSession = await prisma.session.findUnique({ where: { id: loginSession.id } });
            expect(revokedSession?.revokedAt).not.toBeNull();

            // Verify only one valid session exists
            const validSessions = await prisma.session.findMany({
                where: { userId: user.id, revokedAt: null, expiresAt: { gt: new Date() } },
            });
            expect(validSessions).toHaveLength(1);

            // Second refresh with the OLD token: must fail (session revoked)
            const second = await request(app)
                .post('/api/v1/auth/refresh')
                .send({ refreshToken: oldToken });
            expect(second.status).toBe(500);
        });
    });

    // ─── SESSION ROTATION ──────────────────────────────────────

    describe('Session rotation', () => {
        it('should create a new session on each refresh and revoke the old one', async () => {
            await seedUser();

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            const sessionId1 = loginRes.body.session.id;
            const refreshToken1 = loginRes.body.refreshToken;

            const refreshRes = await request(app)
                .post('/api/v1/auth/refresh')
                .send({ refreshToken: refreshToken1 });

            const sessionId2 = refreshRes.body.session.id;
            expect(sessionId2).not.toBe(sessionId1);

            // Old session is revoked in DB
            const oldSession = await prisma.session.findUnique({ where: { id: sessionId1 } });
            expect(oldSession?.revokedAt).not.toBeNull();

            // New session is active
            const newSession = await prisma.session.findUnique({ where: { id: sessionId2 } });
            expect(newSession?.revokedAt).toBeNull();
        });

        it('should support chained refreshes (refresh the refreshed token)', async () => {
            await seedUser();

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            let currentToken = loginRes.body.refreshToken;

            for (let i = 0; i < 3; i++) {
                const res = await request(app)
                    .post('/api/v1/auth/refresh')
                    .send({ refreshToken: currentToken });

                expect(res.status).toBe(200);
                expect(res.body.refreshToken).not.toBe(currentToken);
                currentToken = res.body.refreshToken;
            }
        });
    });

    // ─── LOGOUT ────────────────────────────────────────────────

    describe('POST /api/v1/auth/logout', () => {
        it('should revoke the session when logging out with body token', async () => {
            await seedUser();

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            const { refreshToken, session } = loginRes.body;

            const logoutRes = await request(app)
                .post('/api/v1/auth/logout')
                .send({ refreshToken });

            expect(logoutRes.status).toBe(200);
            expect(logoutRes.body.ok).toBe(true);

            // Session is revoked
            const dbSession = await prisma.session.findUnique({ where: { id: session.id } });
            expect(dbSession?.revokedAt).not.toBeNull();

            // Refresh with the old token should fail
            const refreshRes = await request(app)
                .post('/api/v1/auth/refresh')
                .send({ refreshToken });
            expect(refreshRes.status).toBe(500);
        });
    });

    // ─── ME ────────────────────────────────────────────────────

    describe('GET /api/v1/auth/me', () => {
        it('should return user info with valid accessToken', async () => {
            await seedUser();

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });

            const { accessToken } = loginRes.body;

            const meRes = await request(app)
                .get('/api/v1/auth/me')
                .set('Authorization', `Bearer ${accessToken}`);

            expect(meRes.status).toBe(200);
            expect(meRes.body.user).toHaveProperty('id');
            expect(meRes.body.user).toHaveProperty('role');
            expect(meRes.body.user).toHaveProperty('hasGoogleLogin');
            expect(meRes.body.user.hasGoogleLogin).toBe(false);
            expect(meRes.body.user).toHaveProperty('hasAppleLogin');
            expect(meRes.body.user.hasAppleLogin).toBe(false);
        });

        it('should fail without token', async () => {
            const res = await request(app).get('/api/v1/auth/me');
            expect(res.status).toBe(401);
        });
    });

    describe('POST /api/v1/auth/apple', () => {
        it('rechaza identityToken inválido', async () => {
            const res = await request(app)
                .post('/api/v1/auth/apple')
                .send({
                    identityToken: 'not-a-valid-jwt',
                    rawNonce: 'somerawnoncevaluexxxxxxxxxxxxxxxx',
                });
            expect(res.status).toBe(401);
        });
    });

    describe('POST /api/v1/users/me/delete-account', () => {
        it('anonimiza cuenta, mensajes del remitente, bloquea token y login', async () => {
            const user = await seedUser();
            const hashedPassword = await bcrypt.hash('password123', 10);
            const other = await prisma.user.create({
                data: {
                    name: 'Otro',
                    surname: 'Usuario',
                    email: `other_${Date.now()}@example.com`,
                    dni: `oth${Date.now()}`,
                    password: hashedPassword,
                    role: Role.STUDENT,
                    birthDate: new Date('2000-01-01'),
                    emailVerifiedAt: new Date(),
                    isActive: true,
                },
            });
            await prisma.student.create({ data: { userId: other.id } });
            const conv = await prisma.conversation.create({
                data: {
                    participant1Id: user.id,
                    participant2Id: other.id,
                },
            });
            await prisma.message.create({
                data: {
                    conversationId: conv.id,
                    senderId: user.id,
                    content: 'mensaje privado de prueba',
                },
            });

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });
            const { accessToken } = loginRes.body;

            const del = await request(app)
                .post('/api/v1/users/me/delete-account')
                .set('Authorization', `Bearer ${accessToken}`)
                .send({ confirmPhrase: 'ELIMINAR', password: 'password123' });
            expect(del.status).toBe(200);

            const meAfter = await request(app)
                .get('/api/v1/auth/me')
                .set('Authorization', `Bearer ${accessToken}`);
            expect(meAfter.status).toBe(401);

            const row = await prisma.user.findUnique({ where: { id: user.id } });
            expect(row?.accountDeletedAt).not.toBeNull();
            expect(row?.email.endsWith('@deleted.local')).toBe(true);

            const msgs = await prisma.message.findMany({ where: { senderId: user.id } });
            expect(msgs.length).toBeGreaterThanOrEqual(1);
            expect(msgs.every((m) => m.content === '[Contenido eliminado]')).toBe(true);

            const loginAgain = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: 'test@example.com', password: 'password123' });
            expect(loginAgain.status).toBe(401);
        });

        it('usuario con Apple no requiere contraseña', async () => {
            const hashedPassword = await bcrypt.hash('password123', 10);
            const email = `apple_del_${Date.now()}@example.com`;
            const user = await prisma.user.create({
                data: {
                    name: 'A',
                    surname: 'User',
                    email,
                    dni: `ap${Date.now()}`,
                    password: hashedPassword,
                    role: Role.STUDENT,
                    birthDate: new Date('2000-01-01'),
                    emailVerifiedAt: new Date(),
                    isActive: true,
                    appleSub: `apple.sub.del.${Date.now()}`,
                },
            });
            await prisma.student.create({ data: { userId: user.id } });

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email, password: 'password123' });
            expect(loginRes.status).toBe(200);
            const { accessToken } = loginRes.body;

            const del = await request(app)
                .post('/api/v1/users/me/delete-account')
                .set('Authorization', `Bearer ${accessToken}`)
                .send({ confirmPhrase: 'ELIMINAR' });
            expect(del.status).toBe(200);

            const row = await prisma.user.findUnique({ where: { id: user.id } });
            expect(row?.appleSub).toBeNull();
        });

        it('usuario con Google no requiere contraseña', async () => {
            const hashedPassword = await bcrypt.hash('password123', 10);
            const email = `google_del_${Date.now()}@example.com`;
            const user = await prisma.user.create({
                data: {
                    name: 'G',
                    surname: 'User',
                    email,
                    dni: `gd${Date.now()}`,
                    password: hashedPassword,
                    role: Role.STUDENT,
                    birthDate: new Date('2000-01-01'),
                    emailVerifiedAt: new Date(),
                    isActive: true,
                    googleId: `sub-del-${Date.now()}`,
                },
            });
            await prisma.student.create({ data: { userId: user.id } });

            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email, password: 'password123' });
            expect(loginRes.status).toBe(200);
            const { accessToken } = loginRes.body;

            const del = await request(app)
                .post('/api/v1/users/me/delete-account')
                .set('Authorization', `Bearer ${accessToken}`)
                .send({ confirmPhrase: 'ELIMINAR' });
            expect(del.status).toBe(200);
        });

        it('ADMIN recibe 403', async () => {
            const hashedPassword = await bcrypt.hash('password123', 10);
            const admEmail = `adm_del_${Date.now()}@example.com`;
            await prisma.user.create({
                data: {
                    name: 'Admin',
                    surname: 'Del',
                    email: admEmail,
                    dni: `adm${Date.now()}`,
                    password: hashedPassword,
                    role: Role.ADMIN,
                    birthDate: new Date('1985-01-01'),
                    emailVerifiedAt: new Date(),
                    isActive: true,
                },
            });
            const loginRes = await request(app)
                .post('/api/v1/auth/login')
                .send({ email: admEmail, password: 'password123' });
            expect(loginRes.status).toBe(200);
            const del = await request(app)
                .post('/api/v1/users/me/delete-account')
                .set('Authorization', `Bearer ${loginRes.body.accessToken}`)
                .send({ confirmPhrase: 'ELIMINAR', password: 'password123' });
            expect(del.status).toBe(403);
        });
    });
});
