import { MercadoPagoConfig, Preference, Payment } from 'mercadopago';
import { Payment as AppPayment } from './payment.types';
import CustomizedError from '@shared/classes/CustomizedError';
import { MERCADOPAGO_ACCESS_TOKEN, getMercadoPagoUrl } from '@config/config';

export interface CreatePreferenceData {
  amount: number;
  description: string;
  externalReference: string;
}

export interface MercadoPagoPreference {
  id: string;
  init_point: string;
  sandbox_init_point: string;
}

export default class MercadoPagoService {
  private client: MercadoPagoConfig;

  constructor() {
    this.client = new MercadoPagoConfig({
      accessToken: MERCADOPAGO_ACCESS_TOKEN,
    });
  }

  async createPreference(data: CreatePreferenceData): Promise<MercadoPagoPreference> {
    try {
      const preference = {
        items: [
          {
            id: 'item-1',
            title: data.description,
            unit_price: data.amount,
            quantity: 1,
            currency_id: 'ARS', // Argentine Peso, change as needed
          },
        ],
        external_reference: data.externalReference,
        back_urls: {
          success: `${getMercadoPagoUrl()}/payments/success`,
          failure: `${getMercadoPagoUrl()}/payments/failure`,
          pending: `${getMercadoPagoUrl()}/payments/pending`,
        },
        auto_return: 'approved',
        notification_url: `${getMercadoPagoUrl()}/payments/webhook`,
      };

      const preferenceClient = new Preference(this.client);
      const result = await preferenceClient.create({ body: preference });
      return {
        id: result.id!,
        init_point: result.init_point!,
        sandbox_init_point: result.sandbox_init_point!,
      };
    } catch (error: any) {
      console.error('Error creating Mercado Pago preference:', error);
      throw new CustomizedError('Error al crear la preferencia de pago', 500);
    }
  }

  async getPayment(paymentId: string): Promise<any> {
    try {
      const paymentClient = new Payment(this.client);
      const result = await paymentClient.get({ id: paymentId });
      return result;
    } catch (error: any) {
      console.error('Error getting Mercado Pago payment:', error);
      throw new CustomizedError('Error al obtener el pago', 500);
    }
  }

  async getPaymentStatus(paymentId: string): Promise<string> {
    try {
      const payment = await this.getPayment(paymentId);
      return payment.status;
    } catch (error) {
      console.error('Error getting payment status:', error);
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