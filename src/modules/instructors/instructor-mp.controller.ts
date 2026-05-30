import { Request, Response } from "express";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";
import { ResponseFormatter } from "@shared/utils/responseFormatter";
import InstructorMpService from "./instructor-mp.service";

const successHtml = (title: string, body: string) => `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>${title}</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 480px; margin: 48px auto; padding: 0 16px; color: #1a1a1a; }
    h1 { font-size: 1.35rem; }
    p { line-height: 1.5; color: #444; }
  </style>
</head>
<body>
  <h1>${title}</h1>
  <p>${body}</p>
</body>
</html>`;

export default class InstructorMpController {
  constructor(private readonly mpService: InstructorMpService) {}

  connect: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id as number | undefined;
      if (!userId) return next(new CustomizedError("No autenticado", 401));

      const authorizationUrl = await this.mpService.buildAuthorizationUrlForUser(userId);
      return ResponseFormatter.success(res, { authorizationUrl }, "URL de autorización generada");
    } catch (err) {
      next(err);
    }
  };

  callback: ExpressFunction = async (req, res, next) => {
    try {
      const code = typeof req.query.code === "string" ? req.query.code : "";
      const state = typeof req.query.state === "string" ? req.query.state : "";
      const error = typeof req.query.error === "string" ? req.query.error : "";

      if (error) {
        return res
          .status(400)
          .send(
            successHtml(
              "No se pudo conectar Mercado Pago",
              "La autorización fue cancelada o rechazada. Volvé a la app e intentá de nuevo.",
            ),
          );
      }

      await this.mpService.handleOAuthCallback(code, state);

      return res
        .status(200)
        .send(
          successHtml(
            "Mercado Pago conectado correctamente",
            "Ya podés volver a la app de ManejApp.",
          ),
        );
    } catch (err) {
      if (err instanceof CustomizedError) {
        return res
          .status(err.statusCode)
          .send(
            successHtml(
              "Error al conectar Mercado Pago",
              err.message,
            ),
          );
      }
      next(err);
    }
  };

  status: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id as number | undefined;
      if (!userId) return next(new CustomizedError("No autenticado", 401));

      const status = await this.mpService.getConnectionStatusForUser(userId);
      return ResponseFormatter.success(res, status, "Estado de conexión Mercado Pago");
    } catch (err) {
      next(err);
    }
  };

  disconnect: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id as number | undefined;
      if (!userId) return next(new CustomizedError("No autenticado", 401));

      await this.mpService.disconnectForUser(userId);
      return ResponseFormatter.success(res, { disconnected: true }, "Mercado Pago desconectado");
    } catch (err) {
      next(err);
    }
  };
}
