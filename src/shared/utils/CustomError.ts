export default class CustomError extends Error {
    statusCode: number;

    constructor(message: string, statusCode: number = 500) {
        super(message);
        this.name = 'CustomError';
        this.statusCode = statusCode;
        Error.captureStackTrace(this, this.constructor);
    }
}