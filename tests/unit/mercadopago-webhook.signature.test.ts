import {
  verifyMercadoPagoWebhookSignature,
  signMercadoPagoWebhookTestPayload,
  extractMercadoPagoNotificationDataId,
} from "../../src/modules/payments/mercadopago-webhook.signature";
import { randomUUID } from "crypto";

describe("mercadopago-webhook.signature", () => {
  const secret = "test-secret-key-for-hmac";

  it("verifyMercadoPagoWebhookSignature acepta firma válida", () => {
    const dataId = "12345678";
    const requestId = "req-abc";
    const ts = Date.now();
    const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
    const crypto = require("crypto");
    const v1 = crypto.createHmac("sha256", secret).update(manifest).digest("hex");
    const xSignature = `ts=${ts},v1=${v1}`;
    const r = verifyMercadoPagoWebhookSignature({
      secret,
      xSignature,
      xRequestId: requestId,
      dataId,
    });
    expect(r.ok).toBe(true);
  });

  it("verifyMercadoPagoWebhookSignature rechaza firma incorrecta", () => {
    const r = verifyMercadoPagoWebhookSignature({
      secret,
      xSignature: "ts=1,v1=deadbeef",
      xRequestId: "req",
      dataId: "1",
    });
    expect(r.ok).toBe(false);
    expect(r.reason).toBeDefined();
  });

  it("signMercadoPagoWebhookTestPayload genera headers verificables", () => {
    const requestId = randomUUID();
    const headers = signMercadoPagoWebhookTestPayload({
      secret,
      dataId: "abc-def",
      requestId,
    });
    const bodyId = extractMercadoPagoNotificationDataId({
      query: {},
      body: { data: { id: "abc-def" } },
    });
    const v = verifyMercadoPagoWebhookSignature({
      secret,
      xSignature: headers["x-signature"],
      xRequestId: headers["x-request-id"],
      dataId: bodyId,
    });
    expect(v.ok).toBe(true);
  });
});
