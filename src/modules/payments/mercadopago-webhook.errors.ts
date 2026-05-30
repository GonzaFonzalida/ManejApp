/** Error transitorio: Mercado Pago debe reintentar el webhook (503). */
export class WebhookRetryableError extends Error {
  constructor(
    message: string,
    public readonly correlationId?: string
  ) {
    super(message);
    this.name = "WebhookRetryableError";
  }
}
