export default class CustomizedError extends Error {
    public statusCode: number;
    public isOperational: boolean;
    /** Datos extra para el cliente (ej. missing[] en 422). */
    public payload?: Record<string, unknown>;

    constructor(message: string, statusCode: number = 500, payload?: Record<string, unknown>) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = true;
        this.payload = payload;

        Error.captureStackTrace(this, this.constructor);
    }
}
