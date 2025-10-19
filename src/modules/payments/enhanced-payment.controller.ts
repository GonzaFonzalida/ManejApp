import { Request, Response } from "express";
import EnhancedPaymentService from "./enhanced-payment.service";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import { ResponseFormatter } from "@shared/utils/responseFormatter";
import { AuditAction } from "@shared/services/AuditService";

export default class EnhancedPaymentController {
  constructor(private paymentService: EnhancedPaymentService) {}

  createPayment: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const payment = await this.paymentService.createPayment(req.body, userId);
      
      return ResponseFormatter.created(res, payment, 'Payment created successfully');
    } catch (err) {
      next(err);
    }
  };

  processPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.processPaymentWithRetry(Number(req.params.id));
      
      return ResponseFormatter.success(res, payment, 'Payment processed successfully');
    } catch (err) {
      next(err);
    }
  };

  refundPayment: ExpressFunction = async (req, res, next) => {
    try {
      const { reason } = req.body;
      const userId = (req as any).user?.id;
      
      const payment = await this.paymentService.refundPayment(
        Number(req.params.id), 
        reason, 
        userId
      );
      
      return ResponseFormatter.success(res, payment, 'Payment refunded successfully');
    } catch (err) {
      next(err);
    }
  };

  handleMercadoPagoWebhook: ExpressFunction = async (req, res, next) => {
    try {
      const signature = (req as any).webhookSignature;
      
      await this.paymentService.handleMercadoPagoWebhook(req.body, signature);
      
      return ResponseFormatter.success(res, null, 'Webhook processed successfully');
    } catch (err) {
      next(err);
    }
  };

  getPaymentReport: ExpressFunction = async (req, res, next) => {
    try {
      const filters = {
        startDate: req.query.startDate ? new Date(req.query.startDate as string) : undefined,
        endDate: req.query.endDate ? new Date(req.query.endDate as string) : undefined,
        status: req.query.status as string,
        method: req.query.method as string,
      };

      const report = await this.paymentService.getPaymentReport(filters);
      
      return ResponseFormatter.success(res, report, 'Payment report generated successfully');
    } catch (err) {
      next(err);
    }
  };

  checkPaymentStatus: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.processPaymentWithRetry(Number(req.params.id));
      
      return ResponseFormatter.success(res, { 
        id: payment.id,
        status: payment.status,
        amount: payment.amount,
        method: payment.paymentMethod 
      }, 'Payment status checked');
    } catch (err) {
      next(err);
    }
  };
}