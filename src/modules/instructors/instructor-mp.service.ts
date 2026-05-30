import { randomBytes } from "crypto";
import { MpConnectionStatus } from "@prisma/client";
import { prisma } from "@config/prismaClient";
import CustomizedError from "@shared/classes/CustomizedError";
import {
  getMercadoPagoOAuthClientId,
  getMercadoPagoOAuthRedirectUri,
  MERCADOPAGO_CLIENT_SECRET,
} from "@config/config";

const MP_AUTH_URL = "https://auth.mercadopago.com/authorization";
const MP_TOKEN_URL = "https://api.mercadopago.com/oauth/token";
const OAUTH_STATE_TTL_MS = 15 * 60 * 1000;

export interface InstructorMpConnectionStatus {
  connected: boolean;
  mpConnectionStatus: MpConnectionStatus;
  mpCollectorId: string | null;
  mpPublicKey: string | null;
  mpConnectedAt: Date | null;
  mpTokenExpiresAt: Date | null;
  mpDisconnectedAt: Date | null;
}

interface MercadoPagoTokenResponse {
  access_token?: string;
  refresh_token?: string;
  public_key?: string;
  user_id?: number | string;
  token_type?: string;
  scope?: string;
  expires_in?: number;
  error?: string;
  message?: string;
}

const MP_SECRET_FIELDS = [
  "mpAccessToken",
  "mpRefreshToken",
  "mpOauthState",
  "mpOauthStateExpiresAt",
] as const;

/** Omite tokens OAuth al serializar instructor hacia admin/API pública. */
export function sanitizeInstructorMpFields<T extends Record<string, unknown>>(row: T): Omit<T, (typeof MP_SECRET_FIELDS)[number]> {
  const copy = { ...row };
  for (const key of MP_SECRET_FIELDS) {
    delete copy[key];
  }
  return copy as Omit<T, (typeof MP_SECRET_FIELDS)[number]>;
}

export default class InstructorMpService {
  private assertOAuthConfigured(): void {
    const clientId = getMercadoPagoOAuthClientId();
    if (!clientId || !MERCADOPAGO_CLIENT_SECRET) {
      throw new CustomizedError(
        "OAuth de Mercado Pago no configurado (MERCADOPAGO_CLIENT_ID y MERCADOPAGO_CLIENT_SECRET)",
        503,
      );
    }
  }

  private async getInstructorByUserId(userId: number) {
    const instructor = await prisma.instructor.findUnique({ where: { userId } });
    if (!instructor) {
      throw new CustomizedError("Perfil de instructor no encontrado", 404);
    }
    return instructor;
  }

  async buildAuthorizationUrlForUser(userId: number): Promise<string> {
    this.assertOAuthConfigured();
    const clientId = getMercadoPagoOAuthClientId()!;
    const redirectUri = getMercadoPagoOAuthRedirectUri();
    const instructor = await this.getInstructorByUserId(userId);

    const state = randomBytes(32).toString("hex");
    const expiresAt = new Date(Date.now() + OAUTH_STATE_TTL_MS);

    await prisma.instructor.update({
      where: { id: instructor.id },
      data: {
        mpOauthState: state,
        mpOauthStateExpiresAt: expiresAt,
        mpConnectionStatus: MpConnectionStatus.PENDING,
      },
    });

    const params = new URLSearchParams({
      client_id: clientId,
      response_type: "code",
      platform_id: "mp",
      state,
      redirect_uri: redirectUri,
    });

    return `${MP_AUTH_URL}?${params.toString()}`;
  }

  async handleOAuthCallback(code: string, state: string): Promise<{ instructorId: number }> {
    this.assertOAuthConfigured();
    if (!code?.trim() || !state?.trim()) {
      throw new CustomizedError("Parámetros OAuth inválidos", 400);
    }

    const instructor = await prisma.instructor.findFirst({
      where: {
        mpOauthState: state,
        mpOauthStateExpiresAt: { gt: new Date() },
      },
    });

    if (!instructor) {
      throw new CustomizedError("State OAuth inválido o expirado", 400);
    }

    const tokenData = await this.exchangeAuthorizationCode(code);
    await this.persistTokens(instructor.id, tokenData);

    return { instructorId: instructor.id };
  }

  private async exchangeAuthorizationCode(code: string): Promise<MercadoPagoTokenResponse> {
    const clientId = getMercadoPagoOAuthClientId()!;
    const redirectUri = getMercadoPagoOAuthRedirectUri();

    const body = new URLSearchParams({
      client_id: clientId,
      client_secret: MERCADOPAGO_CLIENT_SECRET!,
      grant_type: "authorization_code",
      code,
      redirect_uri: redirectUri,
    });

    const response = await fetch(MP_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" },
      body: body.toString(),
    });

    const data = (await response.json()) as MercadoPagoTokenResponse;

    if (!response.ok || !data.access_token) {
      console.error("[MP OAuth] Error intercambiando code:", {
        status: response.status,
        error: data.error ?? data.message ?? "unknown",
      });
      throw new CustomizedError("No se pudo conectar la cuenta de Mercado Pago", 502);
    }

    return data;
  }

  private async persistTokens(instructorId: number, data: MercadoPagoTokenResponse): Promise<void> {
    const existing = await prisma.instructor.findUnique({
      where: { id: instructorId },
      select: { mpRefreshToken: true },
    });

    const expiresAt =
      data.expires_in != null && Number.isFinite(data.expires_in)
        ? new Date(Date.now() + data.expires_in * 1000)
        : null;

    const collectorId = data.user_id != null ? String(data.user_id) : null;

    await prisma.instructor.update({
      where: { id: instructorId },
      data: {
        mpAccessToken: data.access_token ?? null,
        mpRefreshToken: data.refresh_token ?? existing?.mpRefreshToken ?? null,
        mpPublicKey: data.public_key ?? null,
        mpCollectorId: collectorId,
        mpTokenType: data.token_type ?? null,
        mpScope: data.scope ?? null,
        mpTokenExpiresAt: expiresAt,
        mpConnectedAt: new Date(),
        mpDisconnectedAt: null,
        mpConnectionStatus: MpConnectionStatus.CONNECTED,
        mpOauthState: null,
        mpOauthStateExpiresAt: null,
      },
    });
  }

  async getConnectionStatusForUser(userId: number): Promise<InstructorMpConnectionStatus> {
    const instructor = await this.getInstructorByUserId(userId);
    return this.mapConnectionStatus(instructor);
  }

  private mapConnectionStatus(instructor: {
    mpConnectionStatus: MpConnectionStatus;
    mpCollectorId: string | null;
    mpPublicKey: string | null;
    mpConnectedAt: Date | null;
    mpTokenExpiresAt: Date | null;
    mpDisconnectedAt: Date | null;
    mpAccessToken: string | null;
  }): InstructorMpConnectionStatus {
    const connected =
      instructor.mpConnectionStatus === MpConnectionStatus.CONNECTED &&
      Boolean(instructor.mpAccessToken) &&
      Boolean(instructor.mpCollectorId);

    return {
      connected,
      mpConnectionStatus: instructor.mpConnectionStatus,
      mpCollectorId: instructor.mpCollectorId,
      mpPublicKey: instructor.mpPublicKey,
      mpConnectedAt: instructor.mpConnectedAt,
      mpTokenExpiresAt: instructor.mpTokenExpiresAt,
      mpDisconnectedAt: instructor.mpDisconnectedAt,
    };
  }

  async disconnectForUser(userId: number): Promise<void> {
    const instructor = await this.getInstructorByUserId(userId);

    await prisma.instructor.update({
      where: { id: instructor.id },
      data: {
        mpAccessToken: null,
        mpRefreshToken: null,
        mpPublicKey: null,
        mpCollectorId: null,
        mpTokenType: null,
        mpScope: null,
        mpTokenExpiresAt: null,
        mpOauthState: null,
        mpOauthStateExpiresAt: null,
        mpConnectionStatus: MpConnectionStatus.DISCONNECTED,
        mpDisconnectedAt: new Date(),
      },
    });
  }

  /** Renueva access_token usando refresh_token (listo para Fase 2). */
  async refreshAccessTokenForInstructor(instructorId: number): Promise<void> {
    this.assertOAuthConfigured();

    const instructor = await prisma.instructor.findUnique({ where: { id: instructorId } });
    if (!instructor?.mpRefreshToken) {
      throw new CustomizedError("No hay refresh token de Mercado Pago", 400);
    }

    const clientId = getMercadoPagoOAuthClientId()!;
    const body = new URLSearchParams({
      client_id: clientId,
      client_secret: MERCADOPAGO_CLIENT_SECRET!,
      grant_type: "refresh_token",
      refresh_token: instructor.mpRefreshToken,
    });

    const response = await fetch(MP_TOKEN_URL, {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded", Accept: "application/json" },
      body: body.toString(),
    });

    const data = (await response.json()) as MercadoPagoTokenResponse;

    if (!response.ok || !data.access_token) {
      console.error("[MP OAuth] Error renovando token:", {
        instructorId,
        status: response.status,
        error: data.error ?? data.message ?? "unknown",
      });
      throw new CustomizedError("No se pudo renovar el token de Mercado Pago", 502);
    }

    await this.persistTokens(instructorId, {
      ...data,
      refresh_token: data.refresh_token ?? instructor.mpRefreshToken,
    });
  }

  private static readonly TOKEN_REFRESH_BUFFER_MS = 5 * 60 * 1000;

  /**
   * Devuelve access token válido del instructor para operaciones marketplace.
   * Renueva automáticamente si está vencido o próximo a vencer.
   */
  async resolveAccessTokenForInstructor(
    instructorId: number
  ): Promise<{ accessToken: string; mpCollectorId: string }> {
    let instructor = await prisma.instructor.findUnique({ where: { id: instructorId } });
    if (!instructor) {
      throw new CustomizedError("Instructor no encontrado", 404);
    }

    if (
      instructor.mpConnectionStatus !== MpConnectionStatus.CONNECTED ||
      !instructor.mpAccessToken ||
      !instructor.mpCollectorId
    ) {
      throw new CustomizedError(
        "El instructor todavía no conectó su cuenta de Mercado Pago. Probá más tarde o elegí otro instructor.",
        409,
        { code: "INSTRUCTOR_MP_NOT_CONNECTED" }
      );
    }

    const expiresAt = instructor.mpTokenExpiresAt;
    const needsRefresh =
      !expiresAt ||
      expiresAt.getTime() <= Date.now() + InstructorMpService.TOKEN_REFRESH_BUFFER_MS;

    if (needsRefresh) {
      try {
        await this.refreshAccessTokenForInstructor(instructorId);
      } catch {
        throw new CustomizedError(
          "La cuenta de Mercado Pago del instructor expiró. Probá más tarde o elegí otro instructor.",
          409,
          { code: "INSTRUCTOR_MP_TOKEN_EXPIRED" }
        );
      }
      instructor = await prisma.instructor.findUnique({ where: { id: instructorId } });
      if (!instructor?.mpAccessToken || !instructor.mpCollectorId) {
        throw new CustomizedError(
          "La cuenta de Mercado Pago del instructor expiró. Probá más tarde o elegí otro instructor.",
          409,
          { code: "INSTRUCTOR_MP_TOKEN_EXPIRED" }
        );
      }
    }

    return {
      accessToken: instructor.mpAccessToken,
      mpCollectorId: instructor.mpCollectorId,
    };
  }
}
