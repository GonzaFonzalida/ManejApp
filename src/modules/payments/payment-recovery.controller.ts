import { Request, Response } from "express";
import PaymentRecoveryService from "./payment-recovery.service";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import { ResponseFormatter } from "@shared/utils/responseFormatter";

export default class PaymentRecoveryController {
  constructor(private recoveryService: PaymentRecoveryService) {}

  // Ejecutar proceso de recuperación manual
  runRecovery: ExpressFunction = async (req, res, next) => {
    try {
      await this.recoveryService.recoverFailedPayments();
      
      return ResponseFormatter.success(res, null, 'Recovery process completed successfully');
    } catch (err) {
      next(err);
    }
  };

  // Verificar integridad de un pago
  verifyPayment: ExpressFunction = async (req, res, next) => {
    try {
      const paymentId = Number(req.params.id);
      const integrity = await this.recoveryService.verifyPaymentIntegrity(paymentId);
      
      return ResponseFormatter.success(res, integrity, 'Payment integrity check completed');
    } catch (err) {
      next(err);
    }
  };

  // Obtener historial de recuperación
  getRecoveryHistory: ExpressFunction = async (req, res, next) => {
    try {
      const paymentId = Number(req.params.id);
      const history = await this.recoveryService.getRecoveryHistory(paymentId);
      
      return ResponseFormatter.success(res, history, 'Recovery history retrieved successfully');
    } catch (err) {
      next(err);
    }
  };
}