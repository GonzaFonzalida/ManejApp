import { MercadoPagoConfig, Preference, Payment } from 'mercadopago';
import CustomizedError from '@shared/classes/CustomizedError';
import { MERCADOPAGO_ACCESS_TOKEN, getMercadoPagoUrl } from '@config/config';
import { logger } from '@logging/LoggerConfig';

export interface CreatePreferenceData {
  amount: number;
  description: string;
  drivingClassId: number;
  externalReference?: string;
}

export interface CreateMarketplacePreferenceData extends CreatePreferenceData {
  marketplaceFee: number;
  metadata?: Record<string, string | number>;
}

export interface MercadoPagoPreference {
  id: string;
  init_point: string;
  sandbox_init_point: string;
}

function buildPreferenceBody(
  data: CreatePreferenceData,
  extra?: { marketplaceFee?: number; metadata?: Record<string, string | number> }
): Record<string, unknown> {
  const externalReference = data.externalReference || `class-${data.drivingClassId}-${Date.now()}`;
  const baseUrl = getMercadoPagoUrl();

  const preference: Record<string, unknown> = {
    items: [
      {
        id: 'item-1',
        title: data.description,
        unit_price: data.amount,
        quantity: 1,
        currency_id: 'ARS',
      },
    ],
    external_reference: externalReference,
    back_urls: {
      success: `${baseUrl}/payments/success`,
      failure: `${baseUrl}/payments/failure`,
      pending: `${baseUrl}/payments/pending`,
    },
    notification_url: `${baseUrl}/api/v1/payments/mercadopago/webhook`,
  };

  if (extra?.marketplaceFee != null && extra.marketplaceFee > 0) {
    preference.marketplace_fee = extra.marketplaceFee;
  }
  if (extra?.metadata && Object.keys(extra.metadata).length > 0) {
    preference.metadata = extra.metadata;
  }

  if (baseUrl.startsWith('https://') || baseUrl.includes('ngrok')) {
    preference.auto_return = 'approved';
  }

  return preference;
}

export default class MercadoPagoService {
  private client: MercadoPagoConfig;

  constructor() {
    this.client = new MercadoPagoConfig({
      accessToken: MERCADOPAGO_ACCESS_TOKEN,
    });
  }

  /** Legacy: preferencia con token de plataforma (sin marketplace_fee). */
  async createPreference(data: CreatePreferenceData): Promise<MercadoPagoPreference> {
    return this.createPreferenceWithToken(data, MERCADOPAGO_ACCESS_TOKEN);
  }

  /** Checkout Pro marketplace: preferencia con token OAuth del vendedor + marketplace_fee. */
  async createMarketplacePreference(
    data: CreateMarketplacePreferenceData,
    sellerAccessToken: string
  ): Promise<MercadoPagoPreference> {
    if (!sellerAccessToken?.trim()) {
      throw new CustomizedError('Token de Mercado Pago del instructor requerido', 400);
    }
    return this.createPreferenceWithToken(
      data,
      sellerAccessToken,
      { marketplaceFee: data.marketplaceFee, metadata: data.metadata }
    );
  }

  private async createPreferenceWithToken(
    data: CreatePreferenceData,
    accessToken: string,
    marketplace?: { marketplaceFee?: number; metadata?: Record<string, string | number> }
  ): Promise<MercadoPagoPreference> {
    try {
      const client = new MercadoPagoConfig({ accessToken });
      const preference = buildPreferenceBody(data, marketplace);
      const preferenceClient = new Preference(client);
      const result = await preferenceClient.create({ body: preference as any });

      logger.info('[MP] Preferencia creada', {
        preferenceId: result.id,
        drivingClassId: data.drivingClassId,
        marketplace: Boolean(marketplace?.marketplaceFee),
        marketplaceFee: marketplace?.marketplaceFee,
      });

      return {
        id: result.id!,
        init_point: result.init_point!,
        sandbox_init_point: result.sandbox_init_point!,
      };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('[MP] Error creando preferencia', undefined, {}, {
        drivingClassId: data.drivingClassId,
        message,
      });
      throw new CustomizedError(`Error al crear la preferencia de pago: ${message}`, 500);
    }
  }

  async getPayment(paymentId: string): Promise<any> {
    return this.getPaymentWithAccessToken(paymentId, MERCADOPAGO_ACCESS_TOKEN);
  }

  async getPaymentWithAccessToken(paymentId: string, accessToken: string): Promise<any> {
    try {
      const client = new MercadoPagoConfig({ accessToken });
      const paymentClient = new Payment(client);
      const result = await paymentClient.get({ id: paymentId });
      return result;
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn('[MP] Error obteniendo pago', { paymentId, message });
      throw new CustomizedError('Error al obtener el pago', 500);
    }
  }

  async getPaymentStatus(paymentId: string): Promise<string> {
    try {
      const payment = await this.getPayment(paymentId);
      return payment.status;
    } catch {
      return 'unknown';
    }
  }

  mapMercadoPagoStatus(mpStatus: string): string {
    switch (mpStatus) {
      case 'approved':
        return 'paid';
      case 'pending':
      case 'in_process':
        return 'pending';
      case 'rejected':
      case 'cancelled':
      case 'refunded':
      case 'charged_back':
        return 'failed';
      default:
        return 'pending';
    }
  }
}
