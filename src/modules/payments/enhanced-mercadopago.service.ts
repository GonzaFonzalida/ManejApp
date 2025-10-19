import { MercadoPagoConfig, Preference, Payment } from 'mercadopago';
import CustomizedError from '@shared/classes/CustomizedError';
import { MERCADOPAGO_ACCESS_TOKEN, getMercadoPagoUrl } from '@config/config';
import crypto from 'crypto';

export default class EnhancedMercadoPagoService {
  private client: MercadoPagoConfig;
  private webhookSecret: string;

  constructor() {
    this.client = new MercadoPagoConfig({
      accessToken: MERCADOPAGO_ACCESS_TOKEN,
    });
    this.webhookSecret = process.env.MERCADOPAGO_WEBHOOK_SECRET || 'default-secret';
  }

  async createPreference(data: {
    amount: number;
    description: string;
    externalReference: string;
    payerEmail?: string;
  }): Promise<{ id: string; init_point: string; sandbox_init_point: string }> {
    try {
      const preference = {
        items: [
          {
            id: 'driving-class',
            title: data.description,
            unit_price: data.amount,
            quantity: 1,
            currency_id: 'ARS',
          },
        ],
        external_reference: data.externalReference,
        payer: data.payerEmail ? { email: data.payerEmail } : undefined,
        back_urls: {
          success: `${getMercadoPagoUrl()}/payments/success`,
          failure: `${getMercadoPagoUrl()}/payments/failure`,
          pending: `${getMercadoPagoUrl()}/payments/pending`,
        },
        auto_return: 'approved',
        notification_url: `${getMercadoPagoUrl()}/api/v1/payments/mercadopago/webhook`,
        expires: true,
        expiration_date_from: new Date().toISOString(),
        expiration_date_to: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // 24 hours
        payment_methods: {
          excluded_payment_types: [
            { id: 'atm' }, // Exclude ATM payments
          ],
          installments: 12, // Max installments
        },
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

  async refundPayment(paymentId: string, amount?: number): Promise<any> {
    try {
      const paymentClient = new Payment(this.client);
      const refundData: any = {};
      
      if (amount) {
        refundData.amount = amount;
      }

      const result = await paymentClient.refund({
        id: paymentId,
        body: refundData,
      });

      return result;
    } catch (error: any) {
      console.error('Error refunding Mercado Pago payment:', error);
      throw new CustomizedError('Error al procesar el reembolso', 500);
    }
  }

  validateWebhookSignature(payload: string, signature: string): boolean {
    try {
      const expectedSignature = crypto
        .createHmac('sha256', this.webhookSecret)
        .update(payload)
        .digest('hex');
      
      return crypto.timingSafeEqual(
        Buffer.from(signature, 'hex'),
        Buffer.from(expectedSignature, 'hex')
      );
    } catch (error) {
      console.error('Error validating webhook signature:', error);
      return false;
    }
  }

  mapMercadoPagoStatus(mpStatus: string): string {
    const statusMap: Record<string, string> = {
      'approved': 'paid',
      'pending': 'pending',
      'in_process': 'pending',
      'in_mediation': 'pending',
      'rejected': 'failed',
      'cancelled': 'cancelled',
      'refunded': 'refunded',
      'charged_back': 'failed',
    };

    return statusMap[mpStatus] || 'pending';
  }

  async getPaymentMethods(): Promise<any> {
    try {
      // This would require additional Mercado Pago SDK setup
      // For now, return common payment methods
      return {
        credit_cards: ['visa', 'mastercard', 'amex'],
        debit_cards: ['visa', 'mastercard'],
        cash: ['rapipago', 'pagofacil'],
        bank_transfer: ['pix'] // For Brazil
      };
    } catch (error) {
      console.error('Error getting payment methods:', error);
      return {};
    }
  }

  async checkPaymentStatus(externalReference: string): Promise<string> {
    try {
      // Search for payment by external reference
      const searchResult = await this.searchPayments({ external_reference: externalReference });
      
      if (searchResult.results && searchResult.results.length > 0) {
        const latestPayment = searchResult.results[0];
        return this.mapMercadoPagoStatus(latestPayment.status);
      }
      
      return 'not_found';
    } catch (error) {
      console.error('Error checking payment status:', error);
      return 'error';
    }
  }

  private async searchPayments(criteria: { external_reference: string }): Promise<any> {
    try {
      const paymentClient = new Payment(this.client);
      const result = await paymentClient.search({
        options: {
          external_reference: criteria.external_reference,
        },
      });
      return result;
    } catch (error) {
      console.error('Error searching payments:', error);
      throw error;
    }
  }
}