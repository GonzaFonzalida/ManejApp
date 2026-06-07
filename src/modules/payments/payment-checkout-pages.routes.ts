import { Router, Request, Response } from "express";

function checkoutPage(title: string, message: string): string {
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title} — ManejApp</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 32rem; margin: 3rem auto; padding: 0 1rem; color: #1a1a1a; }
    h1 { font-size: 1.35rem; margin-bottom: 0.75rem; }
    p { line-height: 1.5; color: #444; }
  </style>
</head>
<body>
  <h1>${title}</h1>
  <p>${message}</p>
  <p>Ya podés volver a la app de ManejApp.</p>
</body>
</html>`;
}

/** Rutas públicas post-checkout (Mercado Pago back_urls). No modifican DB ni confirman pagos. */
const paymentCheckoutPagesRouter = Router();

paymentCheckoutPagesRouter.get("/success", (_req: Request, res: Response) => {
  res
    .status(200)
    .type("html")
    .send(
      checkoutPage(
        "Pago recibido",
        "Estamos confirmando tu reserva. Te avisaremos cuando Mercado Pago confirme el pago."
      )
    );
});

paymentCheckoutPagesRouter.get("/pending", (_req: Request, res: Response) => {
  res
    .status(200)
    .type("html")
    .send(
      checkoutPage(
        "Pago pendiente",
        "Tu pago está pendiente. Te avisaremos cuando Mercado Pago lo confirme."
      )
    );
});

paymentCheckoutPagesRouter.get("/failure", (_req: Request, res: Response) => {
  res
    .status(200)
    .type("html")
    .send(
      checkoutPage(
        "Pago no completado",
        "No pudimos completar el pago. Volvé a la app e intentá nuevamente."
      )
    );
});

export default paymentCheckoutPagesRouter;
