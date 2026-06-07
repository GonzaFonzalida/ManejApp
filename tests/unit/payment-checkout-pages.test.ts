import express from "express";
import request from "supertest";
import paymentCheckoutPagesRouter from "../../src/modules/payments/payment-checkout-pages.routes";

const app = express();
app.use("/payments", paymentCheckoutPagesRouter);

describe("payment checkout pages (public back_urls)", () => {
  it.each([
    ["/payments/success", "Pago recibido"],
    ["/payments/pending", "Pago pendiente"],
    ["/payments/failure", "Pago no completado"],
  ])("GET %s responde 200 HTML público", async (path, titleSnippet) => {
    const res = await request(app).get(path);

    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toMatch(/html/);
    expect(res.text).toContain(titleSnippet);
    expect(res.text).toContain("ManejApp");
  });

  it("acepta query params sin error (no confirma pagos)", async () => {
    const res = await request(app).get(
      "/payments/success?payment_id=123&external_reference=8&collection_status=approved"
    );

    expect(res.status).toBe(200);
    expect(res.text).toContain("Pago recibido");
  });
});
