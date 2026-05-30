import {
  splitGrossByAppCommissionPercent,
  InstructorPayoutStatus,
  marketplaceFeeFromSplit,
} from "../../src/modules/payments/payment-commission.policy";

describe("payment-commission.policy", () => {
  it("splitGrossByAppCommissionPercent: 20% app sobre bruto, instructor neto consistente", () => {
    const s = splitGrossByAppCommissionPercent(10000, 20);
    expect(s.appCommission).toBe(2000);
    expect(s.instructorAmount).toBe(8000);
    expect(s.commissionRate).toBe(20);
    expect(s.grossAmount).toBe(10000);
    expect(s.appCommission + s.instructorAmount).toBe(s.grossAmount);
  });

  it("redondea a 2 decimales en pesos", () => {
    const s = splitGrossByAppCommissionPercent(33.33, 20);
    expect(s.appCommission).toBe(6.67);
    expect(s.instructorAmount).toBeCloseTo(26.66, 2);
    expect(s.appCommission + s.instructorAmount).toBeCloseTo(33.33, 2);
  });

  it("marketplaceFeeFromSplit: entero ARS para Checkout Pro", () => {
    const s = splitGrossByAppCommissionPercent(60000, 20);
    expect(marketplaceFeeFromSplit(s)).toBe(12000);
    expect(s.appCommission).toBe(12000);
    expect(s.instructorAmount).toBe(48000);
  });

  it("InstructorPayoutStatus expone valores esperados", () => {
    expect(InstructorPayoutStatus.PENDING_INTERNAL_PAYOUT).toBe("pending_internal");
    expect(InstructorPayoutStatus.NOT_APPLICABLE).toBe("not_applicable");
  });
});
