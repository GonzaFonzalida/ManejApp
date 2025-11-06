import { Request, Response } from 'express';
import CommissionEnhancedService from './commission-enhanced.service';
import { ExpressFunction } from '@sharedTypes/ExpressFunction';
import { ResponseFormatter } from '@shared/utils/responseFormatter';

export default class CommissionController {
  constructor(private commissionService: CommissionEnhancedService) {}

  createPaymentWithCommission: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const payment = await this.commissionService.createPaymentWithCommission(req.body, userId);
      
      return ResponseFormatter.created(res, payment, 'Pago con comisión creado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  getCommissionReport: ExpressFunction = async (req, res, next) => {
    try {
      const startDate = req.query.startDate ? new Date(req.query.startDate as string) : undefined;
      const endDate = req.query.endDate ? new Date(req.query.endDate as string) : undefined;
      
      const report = await this.commissionService.getCommissionReport(startDate, endDate);
      
      return ResponseFormatter.success(res, report, 'Reporte de comisiones generado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  getInstructorEarnings: ExpressFunction = async (req, res, next) => {
    try {
      const instructorId = Number(req.params.instructorId);
      const startDate = req.query.startDate ? new Date(req.query.startDate as string) : undefined;
      const endDate = req.query.endDate ? new Date(req.query.endDate as string) : undefined;
      
      const earnings = await this.commissionService.getInstructorEarnings(instructorId, startDate, endDate);
      
      return ResponseFormatter.success(res, earnings, 'Ganancias del instructor obtenidas exitosamente');
    } catch (err) {
      next(err);
    }
  };
}