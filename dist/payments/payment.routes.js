"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const GenericRouter_1 = __importDefault(require("../shared/classes/GenericRouter"));
const user_middleware_1 = require("src/users/user.middleware");
const schema = __importStar(require("./payment.schemas"));
class PaymentRouter extends GenericRouter_1.default {
    controller;
    constructor(controller) {
        super();
        this.controller = controller;
        const router = this.init();
        router.post("/", (0, user_middleware_1.validate)(schema.createPaymentSchema), controller.createPayment);
        router.get("/", controller.listPayments);
        router.get("/:id", controller.getPayment);
        router.get("/driving-class/:drivingClassId", controller.getPaymentsByDrivingClass);
        router.put("/:id/status", (0, user_middleware_1.validate)(schema.updatePaymentStatusSchema), controller.updatePaymentStatus);
        router.post("/:id/process", controller.processPayment);
        // Mercado Pago specific routes
        router.post("/mercadopago/preference", (0, user_middleware_1.validate)(schema.createMercadoPagoPreferenceSchema), controller.createMercadoPagoPreference);
        router.post("/mercadopago", (0, user_middleware_1.validate)(schema.createPaymentSchema), controller.createPaymentWithMercadoPago);
        router.post("/mercadopago/webhook", controller.handleMercadoPagoWebhook);
    }
}
exports.default = PaymentRouter;
