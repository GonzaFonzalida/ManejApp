import { normalizeBaseUrl } from "../../src/config/config";

describe("normalizeBaseUrl", () => {
  it("quita slash final", () => {
    expect(normalizeBaseUrl("https://manejapp-1.onrender.com/")).toBe(
      "https://manejapp-1.onrender.com"
    );
  });

  it("no agrega doble slash al concatenar paths", () => {
    const base = normalizeBaseUrl("https://manejapp-1.onrender.com/");
    expect(`${base}/payments/success`).toBe(
      "https://manejapp-1.onrender.com/payments/success"
    );
  });

  it("lanza si la URL está vacía", () => {
    expect(() => normalizeBaseUrl("   ")).toThrow("URL base vacía");
  });
});
