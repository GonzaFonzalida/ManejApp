"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const mercadopago_1 = require("mercadopago");
const dotenv_1 = __importDefault(require("dotenv"));
const path_1 = __importDefault(require("path"));
// Cargar .env desde la raíz del proyecto backend
dotenv_1.default.config({ path: path_1.default.resolve(__dirname, '../.env') });
const ACCESS_TOKEN = process.env.MERCADOPAGO_ACCESS_TOKEN;
console.log("-----------------------------------------");
console.log("🤝 MercadoPago Handshake Protocol");
console.log("-----------------------------------------");
if (!ACCESS_TOKEN) {
    console.error("❌ ERROR: MERCADOPAGO_ACCESS_TOKEN no encontrado en .env");
    process.exit(1);
}
console.log(`🔑 Access Token detectado: ${ACCESS_TOKEN.substring(0, 10)}...`);
const client = new mercadopago_1.MercadoPagoConfig({ accessToken: ACCESS_TOKEN });
const preference = new mercadopago_1.Preference(client);
async function testConnection() {
    try {
        console.log("📡 Conectando con API de MercadoPago...");
        const result = await preference.create({
            body: {
                items: [
                    {
                        id: 'test-handshake',
                        title: 'Test Connectivity Payload',
                        unit_price: 100,
                        quantity: 1,
                    }
                ],
                back_urls: {
                    success: "https://localhost:3000/success",
                    failure: "https://localhost:3000/failure",
                    pending: "https://localhost:3000/pending"
                },
                auto_return: "approved",
            }
        });
        console.log("✅ conexíón EXITOSA!");
        console.log(`🆔 Preference ID: ${result.id}`);
        console.log(`🔗 Init Point: ${result.init_point}`);
        console.log(`🧪 Sandbox Init Point: ${result.sandbox_init_point}`);
        console.log("-----------------------------------------");
        console.log("🚀 L.I.N.K. Phase: VERIFIED");
    }
    catch (error) {
        console.error("❌ ERROR DE CONEXIÓN:");
        console.error(error);
        if (error.cause)
            console.error("Cause:", error.cause);
        process.exit(1);
    }
}
testConnection();
