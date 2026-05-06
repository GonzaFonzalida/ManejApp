import crypto from "crypto";

export interface MercadoPagoWebhookVerifyInput {
  secret: string;
  xSignature?: string;
  xRequestId?: string;
  /** data.id del body o query (MP puede enviarlo en query en algunos casos). */
  dataId: string;
  /** Antireplay: skew máximo del ts del header (ms). */
  maxSkewMs?: number;
}

export interface MercadoPagoWebhookVerifyResult {
  ok: boolean;
  reason?: string;
  tsRaw?: string;
  tsNormalizedMs?: number;
  nowMs?: number;
  deltaMs?: number;
}

/** Extrae data.id desde query (`data.id`) o body JSON. */
export function extractMercadoPagoNotificationDataId(req: {
  query: Record<string, unknown>;
  body?: unknown;
}): string {
  const q = req.query["data.id"];
  const fromQuery = typeof q === "string" ? q : Array.isArray(q) ? q[0] : undefined;
  const body = req.body as { data?: { id?: unknown } } | undefined;
  const fromBody = body?.data?.id != null ? String(body.data.id) : "";
  const raw = (fromQuery != null ? String(fromQuery) : fromBody) || "";
  return /^[a-zA-Z0-9_-]+$/.test(raw) ? raw.toLowerCase() : raw;
}

function parseXSignature(header: string): { ts: string; v1: string } | null {
  const parts = header.split(",");
  let ts: string | undefined;
  let v1: string | undefined;
  for (const part of parts) {
    const trimmed = part.trim();
    const eq = trimmed.indexOf("=");
    if (eq < 0) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (key === "ts") ts = value;
    if (key === "v1") v1 = value;
  }
  if (!ts || !v1) return null;
  return { ts, v1 };
}

function normalizeTsToMs(tsRaw: string): number | undefined {
  if (!/^\d+$/.test(tsRaw)) return undefined;
  if (tsRaw.length === 10) return Number(tsRaw) * 1000; // seconds -> ms
  if (tsRaw.length === 13) return Number(tsRaw); // already ms
  return undefined;
}

export function verifyMercadoPagoWebhookSignature(
  input: MercadoPagoWebhookVerifyInput
): MercadoPagoWebhookVerifyResult {
  const { secret, xSignature, xRequestId, dataId, maxSkewMs = 10 * 60 * 1000 } = input;

  if (!secret) {
    return { ok: false, reason: "missing_secret" };
  }
  if (!xSignature || !xRequestId) {
    return { ok: false, reason: "missing_headers" };
  }
  if (!dataId) {
    return { ok: false, reason: "missing_data_id" };
  }

  const parsed = parseXSignature(xSignature);
  if (!parsed) {
    return { ok: false, reason: "malformed_x_signature" };
  }

  const tsNormalizedMs = normalizeTsToMs(parsed.ts);
  if (tsNormalizedMs === undefined || !Number.isFinite(tsNormalizedMs)) {
    return { ok: false, reason: "invalid_ts_format", tsRaw: parsed.ts };
  }
  const nowMs = Date.now();
  const deltaMs = Math.abs(nowMs - tsNormalizedMs);
  if (deltaMs > maxSkewMs) {
    return {
      ok: false,
      reason: "ts_out_of_range",
      tsRaw: parsed.ts,
      tsNormalizedMs,
      nowMs,
      deltaMs,
    };
  }

  const manifest = `id:${dataId};request-id:${xRequestId};ts:${parsed.ts};`;
  const hmac = crypto.createHmac("sha256", secret).update(manifest).digest("hex");

  if (hmac !== parsed.v1) {
    return {
      ok: false,
      reason: "hmac_mismatch",
      tsRaw: parsed.ts,
      tsNormalizedMs,
      nowMs,
      deltaMs,
    };
  }

  return { ok: true, tsRaw: parsed.ts, tsNormalizedMs, nowMs, deltaMs };
}

/** Genera headers válidos para tests o herramientas internas. */
export function signMercadoPagoWebhookTestPayload(opts: {
  secret: string;
  dataId: string;
  requestId: string;
  ts?: number;
}): { "x-signature": string; "x-request-id": string } {
  const ts = opts.ts ?? Date.now();
  const manifest = `id:${opts.dataId};request-id:${opts.requestId};ts:${ts};`;
  const v1 = crypto.createHmac("sha256", opts.secret).update(manifest).digest("hex");
  return {
    "x-signature": `ts=${ts},v1=${v1}`,
    "x-request-id": opts.requestId,
  };
}
