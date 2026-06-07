jest.mock("@config/config", () => {
  const actual = jest.requireActual("@config/config");
  return {
    ...actual,
    getMercadoPagoUrl: () =>
      actual.normalizeBaseUrl("https://manejapp-1.onrender.com/"),
  };
});

import { buildPreferenceBody } from "../../src/modules/payments/mercadopago.service";

describe("buildPreferenceBody back_urls", () => {
  const baseData = {
    amount: 45000,
    description: "Clase de manejo - Reserva #8",
    drivingClassId: 8,
    externalReference: "8",
  };

  it("genera back_urls sin doble slash", () => {
    const body = buildPreferenceBody(baseData, { marketplaceFee: 9000 });
    const backUrls = body.back_urls as Record<string, string>;

    expect(backUrls.success).toBe("https://manejapp-1.onrender.com/payments/success");
    expect(backUrls.failure).toBe("https://manejapp-1.onrender.com/payments/failure");
    expect(backUrls.pending).toBe("https://manejapp-1.onrender.com/payments/pending");
    for (const url of Object.values(backUrls)) {
      expect(url).not.toMatch(/https:\/\/[^/]+\/\//);
    }
  });

  it("conserva marketplace_fee y notification_url", () => {
    const body = buildPreferenceBody(baseData, { marketplaceFee: 9000 });

    expect(body.marketplace_fee).toBe(9000);
    expect(body.notification_url).toBe(
      "https://manejapp-1.onrender.com/api/v1/payments/mercadopago/webhook"
    );
    expect(body.auto_return).toBe("approved");
  });
});
