"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const mercadopago_1 = require("mercadopago");
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
const config_1 = require("../config/config");
class MercadoPagoService {
    client;
    constructor() {
        this.client = new mercadopago_1.MercadoPagoConfig({
            accessToken: config_1.MERCADOPAGO_ACCESS_TOKEN,
        });
    }
    async createPreference(data) {
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
                    success: `${config_1.APP_URL}/payments/success`,
                    failure: `${config_1.APP_URL}/payments/failure`,
                    pending: `${config_1.APP_URL}/payments/pending`,
                },
                auto_return: 'approved',
                notification_url: `${config_1.APP_URL}/payments/webhook`,
            };
            const preferenceClient = new mercadopago_1.Preference(this.client);
            const result = await preferenceClient.create({ body: preference });
            return {
                id: result.id,
                init_point: result.init_point,
                sandbox_init_point: result.sandbox_init_point,
            };
        }
        catch (error) {
            console.error('Error creating Mercado Pago preference:', error);
            throw new CustomizedError_1.default('Error al crear la preferencia de pago', 500);
        }
    }
    async getPayment(paymentId) {
        try {
            const paymentClient = new mercadopago_1.Payment(this.client);
            const result = await paymentClient.get({ id: paymentId });
            return result;
        }
        catch (error) {
            console.error('Error getting Mercado Pago payment:', error);
            throw new CustomizedError_1.default('Error al obtener el pago', 500);
        }
    }
    async getPaymentStatus(paymentId) {
        try {
            const payment = await this.getPayment(paymentId);
            return payment.status;
        }
        catch (error) {
            console.error('Error getting payment status:', error);
            return 'unknown';
        }
    }
    mapMercadoPagoStatus(mpStatus) {
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
exports.default = MercadoPagoService;
