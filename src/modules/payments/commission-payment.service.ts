import { MercadoPagoConfig, Preference } from 'mercadopago';
import { MERCADOPAGO_ACCESS_TOKEN, getMercadoPagoUrl, APP_COMMISSION_PERCENTAGE } from '@config/config';
import CustomizedError from '@shared/classes/CustomizedError';
import { splitGrossByAppCommissionPercent } from './payment-commission.policy';

export interface CommissionPreferenceData {
  amount: number;
  description: string;
  externalReference: string;
  instructorCollectorId: string; // ID del instructor en MP
  overrideCommissionRate?: number; // Permite forzar el % leyendo DB en el checkout
}

export default class CommissionPaymentService {
  private client: MercadoPagoConfig;
  private appCommissionPercentage: number;
  private appCollectorId: string;

  constructor() {
    this.client = new MercadoPagoConfig({
      accessToken: MERCADOPAGO_ACCESS_TOKEN,
    });
    this.appCommissionPercentage = APP_COMMISSION_PERCENTAGE;
    this.appCollectorId = process.env.APP_COLLECTOR_ID || '';
  }

  calculateCommission(amount: number, overridePercentage?: number): { appCommission: number; instructorAmount: number } {
    const split = splitGrossByAppCommissionPercent(
      amount,
      overridePercentage !== undefined ? overridePercentage : this.appCommissionPercentage
    );
    return { appCommission: split.appCommission, instructorAmount: split.instructorAmount };
  }

  async createPreferenceWithCommission(data: CommissionPreferenceData) {
    try {
      const activePercentage = data.overrideCommissionRate !== undefined ? data.overrideCommissionRate : this.appCommissionPercentage;
      const { appCommission, instructorAmount } = this.calculateCommission(data.amount, data.overrideCommissionRate);

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
        back_urls: {
          success: `${getMercadoPagoUrl()}/payments/success`,
          failure: `${getMercadoPagoUrl()}/payments/failure`,
          pending: `${getMercadoPagoUrl()}/payments/pending`,
        },
        auto_return: 'approved',
        notification_url: `${getMercadoPagoUrl()}/api/v1/payments/mercadopago/webhook`,

        // MARKETPLACE CONFIGURATION - Split payments
        marketplace: 'MARKETPLACE',
        marketplace_fee: appCommission, // Comisión de la app

        // Configuración del split
        additional_info: `Clase de conducción - Comisión app: ${activePercentage}% - Monto total: ${data.amount}`,

        // Split de pagos
        disbursements: [
          {
            amount: instructorAmount,
            external_reference: `instructor_${data.externalReference}`,
            collector_id: data.instructorCollectorId, // Cuenta del instructor
          }
        ]
      };

      const preferenceClient = new Preference(this.client);
      const result = await preferenceClient.create({ body: preference });

      return {
        id: result.id!,
        init_point: result.init_point!,
        sandbox_init_point: result.sandbox_init_point!,
        commission_breakdown: {
          total_amount: data.amount,
          app_commission: appCommission,
          instructor_amount: instructorAmount,
          commission_percentage: activePercentage
        }
      };
    } catch (error: any) {
      console.error('Error creating commission preference:', error);
      throw new CustomizedError('Error al crear preferencia con comisión', 500);
    }
  }
}