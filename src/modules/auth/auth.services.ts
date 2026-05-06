import bcrypt from "bcryptjs";
import { createHash } from "crypto";
import { OAuth2Client } from "google-auth-library";
import { Response, Request } from "express";
import { User as UserInterface, UserWithOutPassword } from "@users/user.types";
import SessionRepository from "./repositories/SessionRepository";
import { signAccessToken, signRefreshToken, verifyRefreshToken } from "@utils/jwtUtils";
import { REFRESH_COOKIE_NAME, refreshCookieOptions } from "@config/cookies";
import { UserRepository } from "@users/repositories/userRepository";
import CustomizedError from "@classes/CustomizedError";
import { GOOGLE_CLIENT_ID, APPLE_CLIENT_ID } from "@config/config";
import { prisma } from "@config/prismaClient";
import { verifyAppleIdentityToken } from "@utils/verifyAppleIdentityToken";

function hashRefreshToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}


export default class AuthService {
  constructor(
    private sessions: SessionRepository,
    private users: UserRepository,
  ) {}

  async googleLogin(req: Request, res: Response, idToken: string): Promise<Error | { accessToken: string; refreshToken: string; user: UserWithOutPassword; session: { id: string; createdAt: Date; expiresAt: Date } }> {
    if (!GOOGLE_CLIENT_ID) {
      return new CustomizedError("Login con Google no está configurado. Falta GOOGLE_CLIENT_ID.", 503);
    }
    const client = new OAuth2Client(GOOGLE_CLIENT_ID);
    let payload: { sub: string; email?: string; email_verified?: boolean; name?: string; given_name?: string; family_name?: string; picture?: string };
    try {
      const ticket = await client.verifyIdToken({ idToken, audience: GOOGLE_CLIENT_ID });
      payload = ticket.getPayload() as any;
      if (!payload?.sub || !payload?.email) {
        return new CustomizedError("Token de Google inválido", 401);
      }
    } catch {
      return new CustomizedError("Token de Google inválido o expirado", 401);
    }

    let user: UserInterface | undefined = await this.users.findByGoogleId(payload.sub) as any;
    if (!user) {
      user = await this.users.findByEmail(payload.email!) as any;
      if (user) {
        const prisma = (await import("@config/prismaClient")).prisma;
        await prisma.user.update({
          where: { id: user.id },
          data: { googleId: payload.sub } as any,
        });
        (user as any).googleId = payload.sub;
      }
    }
    if (!user) {
      const name = payload.given_name || payload.name || "Usuario";
      const surname = payload.family_name || (payload.name?.split(" ").slice(1).join(" ") || "");
      user = await this.users.createGoogleUser({
        email: payload.email!,
        name,
        surname: surname || "Google",
        googleId: payload.sub,
        profileImage: payload.picture,
      }) as any;
    }
    if (!user) return new CustomizedError("Error al crear usuario", 500);

    const blocked = await this.isAccountBlocked(user.id);
    if (blocked) return blocked;

    const accessToken = signAccessToken({ id: user.id, role: user.role });
    const refreshToken = signRefreshToken({ id: user.id, role: user.role });
    const refreshHash = hashRefreshToken(refreshToken);
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30);
    const session = await this.sessions.create({
      userId: user.id,
      refreshHash,
      userAgent: req.headers["user-agent"],
      ip: req.ip,
      expiresAt,
    });
    res.cookie(REFRESH_COOKIE_NAME, refreshToken, refreshCookieOptions);
    await this.users.updateLastLoginAt(user.id);
    return {
      accessToken,
      refreshToken,
      user: this.stripUser(user),
      session: { id: session.id, createdAt: session.createdAt, expiresAt: session.expiresAt },
    };
  }

  async appleLogin(
    req: Request,
    res: Response,
    body: { identityToken: string; rawNonce: string; givenName?: string; familyName?: string },
  ): Promise<Error | { accessToken: string; refreshToken: string; user: UserWithOutPassword; session: { id: string; createdAt: Date; expiresAt: Date } }> {
    if (!APPLE_CLIENT_ID) {
      return new CustomizedError(
        "Login con Apple no está configurado. Falta APPLE_CLIENT_ID (Bundle ID de la app iOS).",
        503,
      );
    }

    let payload: { sub: string; email?: string };
    try {
      const verified = await verifyAppleIdentityToken(body.identityToken, {
        audience: APPLE_CLIENT_ID,
        rawNonce: body.rawNonce,
      });
      payload = { sub: verified.sub, email: verified.email };
    } catch {
      return new CustomizedError("Token de Apple inválido o expirado", 401);
    }

    if (!payload.sub) {
      return new CustomizedError("Token de Apple inválido", 401);
    }

    let user: UserInterface | undefined = (await this.users.findByAppleSub(payload.sub)) as any;

    if (!user && payload.email) {
      const byEmail = (await this.users.findByEmail(payload.email)) as UserInterface | undefined;
      if (byEmail) {
        const existingSub = (byEmail as unknown as { appleSub?: string | null }).appleSub;
        if (existingSub && existingSub !== payload.sub) {
          return new CustomizedError("Este email ya está vinculado a otro Apple ID", 409);
        }
        await prisma.user.update({
          where: { id: byEmail.id },
          data: { appleSub: payload.sub } as any,
        });
        user = { ...byEmail, appleSub: payload.sub } as UserInterface;
      }
    }

    if (!user) {
      const email = payload.email?.trim().toLowerCase();
      if (!email) {
        return new CustomizedError(
          "No se pudo crear la cuenta sin email desde Apple. Si ya tenés cuenta, iniciá sesión en el mismo dispositivo o con Ocultar mi email activado desde el primer inicio.",
          400,
        );
      }
      const name = (body.givenName?.trim() || "Usuario").slice(0, 100) || "Usuario";
      const surname = (body.familyName?.trim() || "Apple").slice(0, 100) || "Apple";
      user = (await this.users.createAppleUser({
        email,
        name,
        surname,
        appleSub: payload.sub,
      })) as any;
    }

    if (!user) return new CustomizedError("Error al crear usuario", 500);

    const blocked = await this.isAccountBlocked(user.id);
    if (blocked) return blocked;

    const accessToken = signAccessToken({ id: user.id, role: user.role });
    const refreshToken = signRefreshToken({ id: user.id, role: user.role });
    const refreshHash = hashRefreshToken(refreshToken);
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30);
    const session = await this.sessions.create({
      userId: user.id,
      refreshHash,
      userAgent: req.headers["user-agent"],
      ip: req.ip,
      expiresAt,
    });
    res.cookie(REFRESH_COOKIE_NAME, refreshToken, refreshCookieOptions);
    await this.users.updateLastLoginAt(user.id);
    return {
      accessToken,
      refreshToken,
      user: this.stripUser(user),
      session: { id: session.id, createdAt: session.createdAt, expiresAt: session.expiresAt },
    };
  }

  async login(req: Request, res: Response, email: string, password: string)
  : Promise<Error | { accessToken: string; refreshToken: string; user: UserWithOutPassword; session: { id: string; createdAt: Date; expiresAt: Date } }> {

    const user = await this.users.findByEmail(email);
    if (!user) {
      return new CustomizedError("Email no encontrado", 401, { code: "EMAIL_NOT_FOUND" });
    }
    const emailVerifiedAt = (user as { emailVerifiedAt?: Date | null }).emailVerifiedAt;
    if (!emailVerifiedAt) {
      return new CustomizedError(
        "Revisá tu correo y tocá el enlace de verificación antes de iniciar sesión.",
        401,
        { code: "PENDING_EMAIL_VERIFICATION" },
      );
    }
    const blocked = await this.isAccountBlocked(user.id);
    if (blocked) return blocked;
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) {
      return new CustomizedError("Contraseña Incorrecta", 401, { code: "INVALID_CREDENTIALS" });
    }

    const accessToken = signAccessToken({ id: user.id, role: user.role });
    const refreshToken = signRefreshToken({ id: user.id, role: user.role });

    const refreshHash = hashRefreshToken(refreshToken);
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30);
    const session = await this.sessions.create({
      userId: user.id,
      refreshHash,
      userAgent: req.headers["user-agent"],
      ip: req.ip,
      expiresAt,
    });
    res.cookie(REFRESH_COOKIE_NAME, refreshToken, refreshCookieOptions);
    await this.users.updateLastLoginAt(user.id);

    return {
      accessToken,
      refreshToken,
      user: this.stripUser(user),
      session: { id: session.id, createdAt: session.createdAt, expiresAt: session.expiresAt },
    };
  }

  async refresh(req: Request, res: Response) {
    const token = req.cookies?.[REFRESH_COOKIE_NAME] || req.body?.refreshToken;
    if (!token) throw new Error("Refresh token no encontrado");

    const payload = verifyRefreshToken(token);

    const alive = await prisma.user.findUnique({
      where: { id: payload.id },
      select: { accountDeletedAt: true, isActive: true },
    });
    if (!alive || alive.accountDeletedAt != null || !alive.isActive) {
      throw new Error("Refresh token inválido");
    }

    const tokenHash = hashRefreshToken(token);
    const allSessions = await this.sessions.findValidByUser(payload.id);
    const match = allSessions.find(s => s.refreshHash === tokenHash) ?? null;
    if (!match) throw new Error("Refresh token inválido");

    const accessToken = signAccessToken({ id: payload.id, role: payload.role });

    const newRefresh = signRefreshToken({ id: payload.id, role: payload.role });
    const newHash = hashRefreshToken(newRefresh);
    await this.sessions.revokeById(match.id);
    const session = await this.sessions.create({
      userId: payload.id,
      refreshHash: newHash,
      userAgent: req.headers["user-agent"],
      ip: req.ip,
      expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30),
    });
    res.cookie(REFRESH_COOKIE_NAME, newRefresh, refreshCookieOptions);

    return {
      accessToken,
      refreshToken: newRefresh,
      session: { id: session.id, createdAt: session.createdAt, expiresAt: session.expiresAt },
    };
  }

  async logout(req: Request, res: Response) {
    const token = req.cookies?.[REFRESH_COOKIE_NAME] || req.body?.refreshToken;
    if (token) {
      try {
        const payload = verifyRefreshToken(token);
        const tokenHash = hashRefreshToken(token);
        const sessions = await this.sessions.findValidByUser(payload.id);
        const match = sessions.find(s => s.refreshHash === tokenHash);
        if (match) await this.sessions.revokeById(match.id);
      } catch {
        // Token expirado o inválido: limpiar cookie igualmente
      }
    }
    res.clearCookie(REFRESH_COOKIE_NAME, { path: refreshCookieOptions.path });
    return { ok: true };
  }

  async listSessions(userId: number) {
    return this.sessions.findValidByUser(userId);
  }

  async revokeSession(userId: number, sessionId: string) {
    const s = await this.sessions.findById(sessionId);
    if (!s || s.userId !== userId) throw new Error("Sesión no encontrada");
    await this.sessions.revokeById(sessionId);
    return { ok: true };
  }

  async revokeAll(userId: number) {
    await this.sessions.revokeAllByUser(userId);
    return { ok: true };
  }

  async getAuthenticatedProfile(userId: number): Promise<CustomizedError | Record<string, unknown>> {
    const u = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        dni: true,
        email: true,
        name: true,
        surname: true,
        role: true,
        createdAt: true,
        birthDate: true,
        isActive: true,
        emailVerifiedAt: true,
        phoneNumber: true,
        location: true,
        profileImage: true,
        googleId: true,
        appleSub: true,
        accountDeletedAt: true,
        student: { select: { experienceLevel: true } },
      },
    });
    if (!u || u.accountDeletedAt != null || !u.isActive) {
      return new CustomizedError("No autorizado", 401);
    }
    const { googleId, appleSub, ...rest } = u as Record<string, unknown> & {
      googleId: string | null;
      appleSub: string | null;
    };
    return { ...rest, hasGoogleLogin: !!googleId, hasAppleLogin: !!appleSub };
  }

  private async isAccountBlocked(userId: number): Promise<CustomizedError | null> {
    const row = await prisma.user.findUnique({
      where: { id: userId },
      select: { accountDeletedAt: true, isActive: true },
    });
    if (!row || row.accountDeletedAt != null || !row.isActive) {
      return new CustomizedError("Cuenta no disponible", 401, { code: "ACCOUNT_UNAVAILABLE" });
    }
    return null;
  }

  private stripUser(user: UserInterface) {
    const u = user as unknown as Record<string, unknown> & {
      password?: string;
      googleId?: string | null;
      appleSub?: string | null;
    };
    const { password: _p, googleId, appleSub, ...rest } = u;
    return {
      ...rest,
      hasGoogleLogin: !!googleId,
      hasAppleLogin: !!appleSub,
    } as UserWithOutPassword & { hasGoogleLogin: boolean; hasAppleLogin: boolean };
  }
}
