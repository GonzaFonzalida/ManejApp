import {
  canReuseMarketplacePreference,
  isLegacyPlatformPreference,
  isMarketplacePreferenceReady,
  mpAmountMatchesDb,
  mpExternalReferenceMatchesBooking,
} from "../../src/modules/payments/payment-marketplace.helpers";

describe("payment-marketplace.helpers", () => {
  describe("isMarketplacePreferenceReady", () => {
    it("true cuando tiene collector, fee e initPoint", () => {
      expect(
        isMarketplacePreferenceReady({
          mpCollectorId: "123",
          marketplaceFee: 12000,
          preferenceInitPoint: "https://mp.test/init",
        })
      ).toBe(true);
    });

    it("false sin marketplace_fee", () => {
      expect(
        isMarketplacePreferenceReady({
          mpCollectorId: "123",
          marketplaceFee: null,
          preferenceInitPoint: "https://mp.test/init",
        })
      ).toBe(false);
    });
  });

  describe("isLegacyPlatformPreference", () => {
    it("detecta preferencia legacy con preferenceId pero sin marketplace", () => {
      expect(
        isLegacyPlatformPreference({
          preferenceId: "pref-old",
          mpCollectorId: null,
          marketplaceFee: null,
        })
      ).toBe(true);
    });

    it("no es legacy si marketplace está completo", () => {
      expect(
        isLegacyPlatformPreference({
          preferenceId: "pref-new",
          mpCollectorId: "99",
          marketplaceFee: 12000,
          preferenceInitPoint: "https://mp.test/init",
        } as any)
      ).toBe(false);
    });
  });

  describe("canReuseMarketplacePreference", () => {
    const base = {
      preferenceId: "pref-1",
      mpCollectorId: "collector-1",
      marketplaceFee: 12000,
      preferenceInitPoint: "https://mp.test/init",
    };

    it("reutiliza si collector y fee coinciden", () => {
      expect(canReuseMarketplacePreference(base, "collector-1", 12000)).toBe(true);
    });

    it("no reutiliza legacy sin marketplace_fee", () => {
      expect(
        canReuseMarketplacePreference(
          { preferenceId: "old", mpCollectorId: null, marketplaceFee: null, preferenceInitPoint: null },
          "collector-1",
          12000
        )
      ).toBe(false);
    });

    it("no reutiliza si cambió el fee", () => {
      expect(canReuseMarketplacePreference(base, "collector-1", 15000)).toBe(false);
    });
  });

  describe("mpExternalReferenceMatchesBooking", () => {
    it("acepta bookingId como external_reference", () => {
      expect(mpExternalReferenceMatchesBooking("42", 42, "42")).toBe(true);
    });

    it("rechaza mismatch", () => {
      expect(mpExternalReferenceMatchesBooking("43", 42, "42")).toBe(false);
    });
  });

  describe("mpAmountMatchesDb", () => {
    it("60000 vs 60000 OK", () => {
      expect(mpAmountMatchesDb(60000, 60000)).toBe(true);
    });

    it("rechaza diferencia mayor a tolerancia en approved", () => {
      expect(mpAmountMatchesDb(50000, 60000)).toBe(false);
    });
  });
});
