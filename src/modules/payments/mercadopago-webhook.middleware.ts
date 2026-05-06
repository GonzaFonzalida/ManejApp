import { Request, Response, NextFunction } from "express";
import { MERCADOPAGO_WEBHOOK_SECRET, NODE_ENV } from "@config/config";
import { logger } from "@logging/LoggerConfig";
import {
  extractMercadoPagoNotificationDataId,
  verifyMercadoPagoWebhookSignature,
} from "./mercadopago-webhook.signature";

/**
 * Valida firma HMAC de Mercado Pago (headers x-signature + x-request-id).
 * Si MERCADOPAGO_WEBHOOK_SECRET no está definido: en desarrollo/test omite validación con warning;
 * en producción no debería ocurrir (config.ts exige el secreto al arrancar).
 */
export function mercadoPagoWebhookSignatureMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
): void {
  const secret = MERCADOPAGO_WEBHOOK_SECRET;

  if (!secret) {
    if (NODE_ENV === "production") {
      logger.error("[MP webhook] Producción sin MERCADOPAGO_WEBHOOK_SECRET");
      res.status(500).json({ ok: false, error: "Webhook mal configurado" });
      return;
    }
    logger.warn(
      "[MP webhook] Firma no validada: MERCADOPAGO_WEBHOOK_SECRET vacío (solo dev/test)"
    );
    next();
    return;
  }

  const body = req.body as { type?: string; data?: { id?: unknown } } | undefined;

  if (body?.type === "payment" && body.data?.id == null) {
    logger.warn("[MP webhook] Notificación payment sin data.id");
    res.status(400).json({ ok: false, error: "Notificación inválida" });
    return;
  }

  if (!body || body.type !== "payment" || body.data?.id == null) {
    next();
    return;
  }

  const dataId = extractMercadoPagoNotificationDataId(req);
  const xSignature = req.headers["x-signature"] as string | undefined;
  const xRequestId = req.headers["x-request-id"] as string | undefined;

  const result = verifyMercadoPagoWebhookSignature({
    secret,
    xSignature,
    xRequestId,
    dataId,
  });

  if (!result.ok) {
    logger.warn("[MP webhook] Firma inválida", {
      reason: result.reason,
      dataId,
      hasSignature: Boolean(xSignature),
      hasRequestId: Boolean(xRequestId),
      tsRaw: result.tsRaw,
      tsNormalizedMs: result.tsNormalizedMs,
      nowMs: result.nowMs,
      deltaMs: result.deltaMs,
    });
    res.status(401).json({ ok: false, error: "Firma inválida" });
    return;
  }

  next();
}
