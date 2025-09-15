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
    }
    init() {
        const router = super.init();
        router.post("/", (0, user_middleware_1.validate)(schema.createPaymentSchema), this.controller.createPayment);
        router.get("/", this.controller.listPayments);
        router.get("/:id", this.controller.getPayment);
        router.get("/driving-class/:drivingClassId", this.controller.getPaymentsByDrivingClass);
        router.put("/:id/status", (0, user_middleware_1.validate)(schema.updatePaymentStatusSchema), this.controller.updatePaymentStatus);
        router.post("/:id/process", this.controller.processPayment);
        // Mercado Pago specific routes
        router.post("/mercadopago/preference", (0, user_middleware_1.validate)(schema.createMercadoPagoPreferenceSchema), this.controller.createMercadoPagoPreference);
        router.post("/mercadopago", (0, user_middleware_1.validate)(schema.createPaymentSchema), this.controller.createPaymentWithMercadoPago);
        router.post("/mercadopago/webhook", this.controller.handleMercadoPagoWebhook);
        return router;
    }
}
exports.default = PaymentRouter;
