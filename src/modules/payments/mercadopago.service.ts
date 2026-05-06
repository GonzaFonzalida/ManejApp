import { MercadoPagoConfig, Preference, Payment } from 'mercadopago';
import { Payment as AppPayment } from './payment.types';
import CustomizedError from '@shared/classes/CustomizedError';
import { MERCADOPAGO_ACCESS_TOKEN, getMercadoPagoUrl } from '@config/config';

export interface CreatePreferenceData {
  amount: number;
  description: string;
  drivingClassId: number; // ID of the driving class for this payment
  externalReference?: string; // Optional, will be generated if not provided
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
      // Generate external reference if not provided
      const externalReference = data.externalReference || `class-${data.drivingClassId}-${Date.now()}`;

      const baseUrl = getMercadoPagoUrl();
      const preference: any = {
        items: [
          {
            id: 'item-1',
            title: data.description,
            unit_price: data.amount,
            quantity: 1,
            currency_id: 'ARS', // Argentine Peso, change as needed
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

      // Only add auto_return if we have a public URL (production or ngrok)
      if (baseUrl.startsWith('https://') || baseUrl.includes('ngrok')) {
        preference.auto_return = 'approved';
      }

      const preferenceClient = new Preference(this.client);
      const result = await preferenceClient.create({ body: preference });

      console.log('MercadoPago preference created successfully:');
      console.log('Result:', JSON.stringify(result, null, 2));

      return {
        id: result.id!,
        init_point: result.init_point!,
        sandbox_init_point: result.sandbox_init_point!,
      };
    } catch (error: any) {
      console.error('Error creating Mercado Pago preference:');
      console.error('Error message:', error.message);
      console.error('Error details:', JSON.stringify(error, null, 2));
      console.error('Data received:', JSON.stringify(data, null, 2));
      throw new CustomizedError(`Error al crear la preferencia de pago: ${error.message}`, 500);
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