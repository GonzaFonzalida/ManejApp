import { Request, Response, NextFunction } from "express";
import CustomizedError from "../classes/CustomizedError";
import { logger } from "../logging/LoggerConfig";

const errorHandler = (err: Error | CustomizedError, req: Request, res: Response, next: NextFunction) => {
    const time = Date.now();
    const responseTime = time - (req.startTime || time);

    // Use request logger if available, otherwise use global logger
    const requestLogger = req.logger || logger;

    if (err instanceof CustomizedError) {
        // Log custom errors as warnings (they're expected errors)
        requestLogger.warn(
            `Custom error: ${err.message}`,
            {
                statusCode: err.statusCode,
                responseTime,
            },
            {
                errorType: 'CustomizedError',
                host: req.host,
                url: req.originalUrl,
                method: req.method,
            }
        );

        return res.status(err.statusCode).json({
            message: err.message,
            host: req.host,
            url: req.originalUrl,
            method: req.method,
            statusCode: err.statusCode,
            time: time,
        });
    }

    // Log unexpected errors as errors
    requestLogger.error(
    `Unhandled error: ${err.message}`,
    {
        name: err.name,
        message: err.message,
        stack: err.stack,
    },
    {
        statusCode: 500,
        responseTime,
    },
    {
        errorType: 'UnhandledError',
        host: req.host,
        url: req.originalUrl,
        method: req.method,
    }
);

}
export default errorHandler;
