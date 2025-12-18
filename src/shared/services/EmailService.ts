import nodemailer from 'nodemailer';

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
}