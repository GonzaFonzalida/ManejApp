import { BookingStatus, SlotStatus } from "@prisma/client";
import CustomizedError from "../../src/shared/classes/CustomizedError";
import PaymentService from "../../src/modules/payments/payment.services";
import { WebhookRetryableError } from "../../src/modules/payments/mercadopago-webhook.errors";

jest.mock("@config/prismaClient", () => ({
  prisma: {
    drivingClass: { findUnique: jest.fn() },
    scheduleSlot: { findFirst: jest.fn() },
    instructor: { findUnique: jest.fn() },
    student: { findUnique: jest.fn() },
    payment: { findMany: jest.fn() },
    $transaction: jest.fn(),
  },
}));

import { prisma } from "@config/prismaClient";

const mockPrisma = prisma as jest.Mocked<typeof prisma>;

function buildService() {
  const paymentRepo = {
    getPaymentsByDrivingClass: jest.fn(),
    updatePaymentWithMercadoPagoData: jest.fn(),
    getPaymentByExternalReference: jest.fn(),
    getPaymentByPaymentId: jest.fn(),
    getPaymentByPreferenceId: jest.fn(),
    getPaymentById: jest.fn(),
    createPayment: jest.fn(),
    updatePaymentStatus: jest.fn(),
    listPayments: jest.fn(),
  };
  const mercadoPagoService = {
    createPreference: jest.fn(),
    createMarketplacePreference: jest.fn(),
    getPayment: jest.fn(),
    getPaymentWithAccessToken: jest.fn(),
    getPaymentStatus: jest.fn(),
    mapMercadoPagoStatus: jest.fn(),
  };
  const notificationService = { sendPushToUser: jest.fn() };
  const instructorMpService = {
    resolveAccessTokenForInstructor: jest.fn(),
    refreshAccessTokenForInstructor: jest.fn(),
  };

  const service = new PaymentService(
    paymentRepo as any,
    mercadoPagoService as any,
    notificationService as any,
    instructorMpService as any
  );

  return { service, paymentRepo, mercadoPagoService, instructorMpService, notificationService };
}

const bookingBase = {
  id: 42,
  status: BookingStatus.PENDING_PAYMENT,
  instructorId: 7,
  studentId: 15,
  amount: 60000,
  student: { userId: 100 },
};

const slotBase = {
  id: "slot-1",
  status: SlotStatus.HELD,
  heldUntil: new Date(Date.now() + 60_000),
  drivingClassId: 42,
};

const paymentPending = {
  id: 1,
  status: "pending",
  amount: 60000,
  provider: "mercadopago",
  preferenceId: null,
  mpCollectorId: null,
  marketplaceFee: null,
  preferenceInitPoint: null,
  externalReference: null,
  drivingClassId: 42,
};

describe("PaymentService marketplace — createPreferenceForBooking", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (mockPrisma.drivingClass.findUnique as jest.Mock).mockResolvedValue(bookingBase);
    (mockPrisma.scheduleSlot.findFirst as jest.Mock).mockResolvedValue(slotBase);
    (mockPrisma.instructor.findUnique as jest.Mock).mockResolvedValue({ id: 7, commissionRate: 20 });
  });

  it("A) instructor conectado: usa token instructor y marketplace_fee 12000", async () => {
    const { service, paymentRepo, mercadoPagoService, instructorMpService } = buildService();
    paymentRepo.getPaymentsByDrivingClass.mockResolvedValue([paymentPending]);
    instructorMpService.resolveAccessTokenForInstructor.mockResolvedValue({
      accessToken: "instructor-oauth-token",
      mpCollectorId: "collector-99",
    });
    mercadoPagoService.createMarketplacePreference.mockResolvedValue({
      id: "pref-new",
      init_point: "https://mp.test/init",
      sandbox_init_point: "https://mp.test/sandbox",
    });
    paymentRepo.updatePaymentWithMercadoPagoData.mockResolvedValue({});

    const result = await service.createPreferenceForBooking(42, 100, "STUDENT");

    expect(instructorMpService.resolveAccessTokenForInstructor).toHaveBeenCalledWith(7);
    expect(mercadoPagoService.createMarketplacePreference).toHaveBeenCalledWith(
      expect.objectContaining({
        amount: 60000,
        marketplaceFee: 12000,
        externalReference: "42",
      }),
      "instructor-oauth-token"
    );
    expect(mercadoPagoService.createPreference).not.toHaveBeenCalled();
    expect(result.preferenceId).toBe("pref-new");
    expect(paymentRepo.updatePaymentWithMercadoPagoData).toHaveBeenCalledWith(
      1,
      expect.objectContaining({ marketplaceFee: 12000, mpCollectorId: "collector-99" })
    );
  });

  it("B) instructor sin MP: error INSTRUCTOR_MP_NOT_CONNECTED, no llama MP", async () => {
    const { service, paymentRepo, mercadoPagoService, instructorMpService } = buildService();
    paymentRepo.getPaymentsByDrivingClass.mockResolvedValue([paymentPending]);
    instructorMpService.resolveAccessTokenForInstructor.mockRejectedValue(
      new CustomizedError("El instructor todavía no conectó su cuenta de Mercado Pago.", 409, {
        code: "INSTRUCTOR_MP_NOT_CONNECTED",
      })
    );

    await expect(service.createPreferenceForBooking(42, 100, "STUDENT")).rejects.toMatchObject({
      statusCode: 409,
      payload: { code: "INSTRUCTOR_MP_NOT_CONNECTED" },
    });
    expect(mercadoPagoService.createMarketplacePreference).not.toHaveBeenCalled();
    expect(paymentRepo.updatePaymentWithMercadoPagoData).not.toHaveBeenCalled();
  });

  it("D) refresh fallido: INSTRUCTOR_MP_TOKEN_EXPIRED, no usa token plataforma", async () => {
    const { service, paymentRepo, mercadoPagoService, instructorMpService } = buildService();
    paymentRepo.getPaymentsByDrivingClass.mockResolvedValue([paymentPending]);
    instructorMpService.resolveAccessTokenForInstructor.mockRejectedValue(
      new CustomizedError("La cuenta de Mercado Pago del instructor expiró.", 409, {
        code: "INSTRUCTOR_MP_TOKEN_EXPIRED",
      })
    );

    await expect(service.createPreferenceForBooking(42, 100, "STUDENT")).rejects.toMatchObject({
      payload: { code: "INSTRUCTOR_MP_TOKEN_EXPIRED" },
    });
    expect(mercadoPagoService.createMarketplacePreference).not.toHaveBeenCalled();
    expect(mercadoPagoService.createPreference).not.toHaveBeenCalled();
  });

  it("E) preferencia legacy: no reutiliza, regenera marketplace", async () => {
    const { service, paymentRepo, mercadoPagoService, instructorMpService } = buildService();
    paymentRepo.getPaymentsByDrivingClass.mockResolvedValue([
      {
        ...paymentPending,
        preferenceId: "pref-legacy",
        preferenceInitPoint: "https://old-platform/init",
      },
    ]);
    instructorMpService.resolveAccessTokenForInstructor.mockResolvedValue({
      accessToken: "instructor-token",
      mpCollectorId: "col-1",
    });
    mercadoPagoService.createMarketplacePreference.mockResolvedValue({
      id: "pref-marketplace",
      init_point: "https://mp.test/new",
      sandbox_init_point: "",
    });
    paymentRepo.updatePaymentWithMercadoPagoData.mockResolvedValue({});

    const result = await service.createPreferenceForBooking(42, 100, "STUDENT");

    expect(mercadoPagoService.createMarketplacePreference).toHaveBeenCalled();
    expect(result.preferenceId).toBe("pref-marketplace");
  });

  it("E-bis) preferencia marketplace válida: reutiliza sin llamar MP", async () => {
    const { service, paymentRepo, mercadoPagoService, instructorMpService } = buildService();
    paymentRepo.getPaymentsByDrivingClass.mockResolvedValue([
      {
        ...paymentPending,
        preferenceId: "pref-ok",
        mpCollectorId: "col-1",
        marketplaceFee: 12000,
        preferenceInitPoint: "https://mp.test/reuse",
      },
    ]);
    instructorMpService.resolveAccessTokenForInstructor.mockResolvedValue({
      accessToken: "instructor-token",
      mpCollectorId: "col-1",
    });

    const result = await service.createPreferenceForBooking(42, 100, "STUDENT");

    expect(mercadoPagoService.createMarketplacePreference).not.toHaveBeenCalled();
    expect(result).toEqual({ preferenceId: "pref-ok", initPoint: "https://mp.test/reuse" });
  });
});

describe("PaymentService marketplace — webhook", () => {
  it("G) no concilia si no puede obtener pago remoto — lanza WebhookRetryableError", async () => {
    const { service, mercadoPagoService, paymentRepo } = buildService();
    mercadoPagoService.getPayment.mockRejectedValue(new Error("403 forbidden"));
    paymentRepo.getPaymentByPaymentId.mockResolvedValue(null);
    (mockPrisma.payment.findMany as jest.Mock).mockResolvedValue([]);

    await expect(
      service.handleMercadoPagoWebhook(
        { type: "payment", data: { id: "999" } },
        { correlationId: "test-corr-1" }
      )
    ).rejects.toBeInstanceOf(WebhookRetryableError);
  });

  it("G-bis) external_reference desconocido: no lanza, no actualiza", async () => {
    const { service, mercadoPagoService, paymentRepo } = buildService();
    mercadoPagoService.getPayment.mockResolvedValue({
      id: "888",
      status: "approved",
      external_reference: "99999",
      transaction_amount: 60000,
    });
    paymentRepo.getPaymentByExternalReference.mockResolvedValue(null);

    await expect(
      service.handleMercadoPagoWebhook(
        { type: "payment", data: { id: "888" } },
        { correlationId: "test-corr-2" }
      )
    ).resolves.toBeUndefined();
    expect(mockPrisma.$transaction).not.toHaveBeenCalled();
  });
});
