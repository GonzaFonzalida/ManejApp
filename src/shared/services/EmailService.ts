import nodemailer from 'nodemailer';
import ReportService, { AppStatistics } from './ReportService';

export default class EmailService {
  private transporter: nodemailer.Transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });
  }

  async sendVerificationEmail(email: string, token: string): Promise<void> {
    // Para app móvil, usar deep link o esquema personalizado
    const verificationUrl = process.env.IS_MOBILE_APP === 'true'
      ? `${process.env.MOBILE_APP_SCHEME || 'manejapp'}://verify-email?token=${token}`
      : `${process.env.FRONTEND_URL}/verify-email?token=${token}`;

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Verifica tu cuenta en ManejApp',
      html: `
        <h1>¡Bienvenido a ManejApp!</h1>
        <p>Para completar tu registro, por favor verifica tu email haciendo clic en el siguiente enlace:</p>
        <a href="${verificationUrl}">Verificar Email</a>
        <p>Si no puedes hacer clic en el enlace, copia y pega esta URL en tu app:</p>
        <p>${verificationUrl}</p>
        <p>Este enlace expirará en 24 horas.</p>
        <p>Si no solicitaste esta verificación, ignora este email.</p>
      `,
    };

    await this.transporter.sendMail(mailOptions);
  }

  async sendPasswordResetEmail(email: string, token: string): Promise<void> {
    const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${token}`;

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Restablecer contraseña en ManejApp',
      html: `
        <h1>Restablecer Contraseña</h1>
        <p>Haz clic en el siguiente enlace para restablecer tu contraseña:</p>
        <a href="${resetUrl}">Restablecer Contraseña</a>
        <p>Si no puedes hacer clic en el enlace, copia y pega esta URL en tu navegador:</p>
        <p>${resetUrl}</p>
        <p>Este enlace expirará en 1 hora.</p>
        <p>Si no solicitaste este restablecimiento, ignora este email.</p>
      `,
    };

    await this.transporter.sendMail(mailOptions);
  }

  async sendSystemReport(recipients: string[], statistics: AppStatistics): Promise<void> {
    const reportHtml = this.generateReportHtml(statistics);

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: recipients.join(', '),
      subject: `ManejApp - Reporte del Sistema - ${new Date().toLocaleDateString()}`,
      html: reportHtml,
    };

    await this.transporter.sendMail(mailOptions);
  }

  async sendErrorAlert(recipients: string[], error: Error, context?: any): Promise<void> {
    const alertHtml = this.generateErrorAlertHtml(error, context);

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: recipients.join(', '),
      subject: '🚨 ManejApp - Alerta de Error Crítico',
      html: alertHtml,
    };

    await this.transporter.sendMail(mailOptions);
  }

  private generateReportHtml(stats: AppStatistics): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Reporte del Sistema ManejApp</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .header { background: #1976d2; color: white; padding: 20px; border-radius: 5px; }
          .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
          .metric { display: inline-block; margin: 10px; padding: 10px; background: #f5f5f5; border-radius: 5px; }
          .number { font-size: 24px; font-weight: bold; color: #1976d2; }
          .label { font-size: 12px; color: #666; }
          .error { color: #d32f2f; }
          .success { color: #388e3c; }
          .warning { color: #f57c00; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>📊 Reporte del Sistema ManejApp</h1>
          <p>Generado el ${new Date().toLocaleString()}</p>
        </div>

        <div class="section">
          <h2>👥 Usuarios</h2>
          <div class="metric">
            <div class="number">${stats.users.total}</div>
            <div class="label">Total</div>
          </div>
          <div class="metric">
            <div class="number success">${stats.users.active}</div>
            <div class="label">Activos</div>
          </div>
          <div class="metric">
            <div class="number warning">${stats.users.unverified}</div>
            <div class="label">Sin Verificar</div>
          </div>
          <div class="metric">
            <div class="number">${stats.users.students}</div>
            <div class="label">Estudiantes</div>
          </div>
          <div class="metric">
            <div class="number">${stats.users.instructors}</div>
            <div class="label">Instructores</div>
          </div>
          <div class="metric">
            <div class="number">${stats.users.admins}</div>
            <div class="label">Administradores</div>
          </div>
        </div>

        <div class="section">
          <h2>🚗 Instructores</h2>
          <div class="metric">
            <div class="number">${stats.instructors.total}</div>
            <div class="label">Total</div>
          </div>
          <div class="metric">
            <div class="number success">${stats.instructors.valid}</div>
            <div class="label">Válidos</div>
          </div>
          <div class="metric">
            <div class="number error">${stats.instructors.invalid}</div>
            <div class="label">Inválidos</div>
          </div>
          <div class="metric">
            <div class="number">${stats.instructors.withCars}</div>
            <div class="label">Con Auto</div>
          </div>
          <div class="metric">
            <div class="number warning">${stats.instructors.withoutCars}</div>
            <div class="label">Sin Auto</div>
          </div>
        </div>

        <div class="section">
          <h2>📅 Clases de Manejo</h2>
          <div class="metric">
            <div class="number">${stats.classes.total}</div>
            <div class="label">Total</div>
          </div>
          <div class="metric">
            <div class="number">${stats.classes.scheduled}</div>
            <div class="label">Programadas</div>
          </div>
          <div class="metric">
            <div class="number success">${stats.classes.completed}</div>
            <div class="label">Completadas</div>
          </div>
          <div class="metric">
            <div class="number error">${stats.classes.cancelled}</div>
            <div class="label">Canceladas</div>
          </div>
          <div class="metric">
            <div class="number">${stats.classes.today}</div>
            <div class="label">Hoy</div>
          </div>
        </div>

        <div class="section">
          <h2>💰 Pagos</h2>
          <div class="metric">
            <div class="number">${stats.payments.total}</div>
            <div class="label">Total</div>
          </div>
          <div class="metric">
            <div class="number warning">${stats.payments.pending}</div>
            <div class="label">Pendientes</div>
          </div>
          <div class="metric">
            <div class="number success">${stats.payments.completed}</div>
            <div class="label">Completados</div>
          </div>
          <div class="metric">
            <div class="number error">${stats.payments.failed}</div>
            <div class="label">Fallidos</div>
          </div>
          <div class="metric">
            <div class="number">$${stats.payments.totalAmount.toFixed(2)}</div>
            <div class="label">Monto Total</div>
          </div>
        </div>

        <div class="section">
          <h2>⚙️ Sistema</h2>
          <div class="metric">
            <div class="number">${stats.system.uptime}</div>
            <div class="label">Uptime</div>
          </div>
          <div class="metric">
            <div class="number ${stats.system.errorCount > 0 ? 'error' : 'success'}">${stats.system.errorCount}</div>
            <div class="label">Errores (24h)</div>
          </div>
        </div>

        ${stats.system.recentErrors.length > 0 ? `
        <div class="section">
          <h2>🚨 Errores Recientes</h2>
          ${stats.system.recentErrors.map(error => `
            <div style="margin: 10px 0; padding: 10px; background: #ffebee; border-left: 4px solid #d32f2f;">
              <strong>${new Date(error.timestamp).toLocaleString()}</strong><br>
              ${error.message}
            </div>
          `).join('')}
        </div>
        ` : ''}
      </body>
      </html>
    `;
  }

  private generateErrorAlertHtml(error: Error, context?: any): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Alerta de Error Crítico</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .alert { background: #ffebee; border: 2px solid #d32f2f; padding: 20px; border-radius: 5px; }
          .error-details { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; font-family: monospace; }
        </style>
      </head>
      <body>
        <div class="alert">
          <h1>🚨 Error Crítico en ManejApp</h1>
          <p><strong>Hora:</strong> ${new Date().toLocaleString()}</p>
          <p><strong>Error:</strong> ${error.message}</p>

          <h3>Stack Trace:</h3>
          <div class="error-details">
            ${error.stack?.replace(/\n/g, '<br>') || 'No stack trace available'}
          </div>

          ${context ? `
          <h3>Contexto Adicional:</h3>
          <div class="error-details">
            ${JSON.stringify(context, null, 2).replace(/\n/g, '<br>')}
          </div>
          ` : ''}

          <p style="color: #d32f2f; margin-top: 20px;">
            <strong>Acción requerida:</strong> Revisar logs del sistema y resolver el problema inmediatamente.
          </p>
        </div>
      </body>
      </html>
    `;
  }

  async sendUserNotification(email: string, title: string, body: string, type: 'info' | 'success' | 'warning' | 'error' = 'info'): Promise<void> {
    const htmlContent = this.generateUserNotificationHtml(title, body, type);

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: `ManejApp - ${title}`,
      html: htmlContent,
    };

    await this.transporter.sendMail(mailOptions);
  }

  async sendClassReminder(email: string, classInfo: { date: string, instructor: string, location?: string }): Promise<void> {
    const htmlContent = this.generateClassReminderHtml(classInfo);

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'ManejApp - Recordatorio de Clase',
      html: htmlContent,
    };

    await this.transporter.sendMail(mailOptions);
  }

  async sendPaymentConfirmation(email: string, paymentInfo: { amount: number, classDate: string, instructor: string }): Promise<void> {
    const htmlContent = this.generatePaymentConfirmationHtml(paymentInfo);

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'ManejApp - Confirmación de Pago',
      html: htmlContent,
    };

    await this.transporter.sendMail(mailOptions);
  }

  private generateUserNotificationHtml(title: string, body: string, type: string): string {
    const colors = {
      info: '#2196f3',
      success: '#4caf50',
      warning: '#ff9800',
      error: '#f44336'
    };

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Notificación ManejApp</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .notification { border-left: 4px solid ${colors[type as keyof typeof colors]}; padding: 20px; background: #f9f9f9; border-radius: 5px; }
          .title { font-size: 18px; font-weight: bold; margin-bottom: 10px; color: ${colors[type as keyof typeof colors]}; }
          .body { font-size: 14px; line-height: 1.5; }
          .footer { margin-top: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="notification">
          <div class="title">${title}</div>
          <div class="body">${body.replace(/\n/g, '<br>')}</div>
        </div>
        <div class="footer">
          Esta es una notificación automática de ManejApp.<br>
          Puedes cambiar tus preferencias de notificación en la configuración de tu cuenta.
        </div>
      </body>
      </html>
    `;
  }

  private generateClassReminderHtml(classInfo: any): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Recordatorio de Clase</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .reminder { background: #e3f2fd; padding: 20px; border-radius: 5px; border-left: 4px solid #2196f3; }
          .title { font-size: 20px; font-weight: bold; color: #1976d2; margin-bottom: 15px; }
          .info { margin: 10px 0; }
          .label { font-weight: bold; color: #666; }
          .highlight { color: #1976d2; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="reminder">
          <div class="title">🔔 Recordatorio de Clase</div>
          <div class="info">
            <span class="label">Fecha y Hora:</span> <span class="highlight">${new Date(classInfo.date).toLocaleString()}</span>
          </div>
          <div class="info">
            <span class="label">Instructor:</span> <span class="highlight">${classInfo.instructor}</span>
          </div>
          ${classInfo.location ? `
          <div class="info">
            <span class="label">Ubicación:</span> <span class="highlight">${classInfo.location}</span>
          </div>
          ` : ''}
          <div style="margin-top: 20px; padding: 15px; background: #fff; border-radius: 5px;">
            <strong>¡No olvides llegar 15 minutos antes!</strong><br>
            Recuerda llevar tu licencia de conducir y documentos personales.
          </div>
        </div>
      </body>
      </html>
    `;
  }

  private generatePaymentConfirmationHtml(paymentInfo: any): string {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Confirmación de Pago</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 20px; }
          .confirmation { background: #e8f5e8; padding: 20px; border-radius: 5px; border-left: 4px solid #4caf50; }
          .title { font-size: 20px; font-weight: bold; color: #2e7d32; margin-bottom: 15px; }
          .amount { font-size: 24px; font-weight: bold; color: #2e7d32; text-align: center; margin: 20px 0; }
          .info { margin: 10px 0; }
          .label { font-weight: bold; color: #666; }
        </style>
      </head>
      <body>
        <div class="confirmation">
          <div class="title">✅ Pago Confirmado</div>
          <div class="amount">$${paymentInfo.amount.toFixed(2)}</div>
          <div class="info">
            <span class="label">Clase:</span> ${new Date(paymentInfo.classDate).toLocaleString()}
          </div>
          <div class="info">
            <span class="label">Instructor:</span> ${paymentInfo.instructor}
          </div>
          <div style="margin-top: 20px; padding: 15px; background: #fff; border-radius: 5px;">
            Tu pago ha sido procesado exitosamente. Recibirás más detalles sobre tu clase pronto.
          </div>
        </div>
      </body>
      </html>
    `;
  }
}