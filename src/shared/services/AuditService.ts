import { logger } from '@logging/LoggerConfig';

export enum AuditAction {
  LOGIN = 'LOGIN',
  LOGOUT = 'LOGOUT',
  CREATE = 'CREATE',
  UPDATE = 'UPDATE',
  DELETE = 'DELETE',
  VIEW = 'VIEW',
  PAYMENT = 'PAYMENT',
  PERMISSION_CHANGE = 'PERMISSION_CHANGE'
}

export interface AuditLog {
  userId?: number;
  action: AuditAction;
  resource: string;
  resourceId?: string | number;
  details?: any;
  ip?: string;
  userAgent?: string;
}

export class AuditService {
  static log(auditData: AuditLog): void {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level: 'audit',
      ...auditData
    };

    logger.info('Audit Log', {
      module: 'audit',
      function: 'log',
      userId: auditData.userId,
      action: auditData.action,
      resource: auditData.resource,
      resourceId: auditData.resourceId,
      ip: auditData.ip
    }, auditData.details);
  }

  static logUserAction(userId: number, action: AuditAction, resource: string, resourceId?: string | number, details?: any, req?: any): void {
    this.log({
      userId,
      action,
      resource,
      resourceId,
      details,
      ip: req?.ip || req?.connection?.remoteAddress,
      userAgent: req?.get('User-Agent')
    });
  }

  static logSecurityEvent(action: AuditAction, details: any, req?: any): void {
    this.log({
      action,
      resource: 'security',
      details,
      ip: req?.ip || req?.connection?.remoteAddress,
      userAgent: req?.get('User-Agent')
    });
  }
}