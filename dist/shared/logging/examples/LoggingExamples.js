"use strict";
/**
 * Ejemplos de uso del sistema de logging en ManejApp
 *
 * Este archivo muestra las mejores prácticas para usar el sistema de logging
 * en diferentes partes de la aplicación.
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.CorrelatedLoggingExample = exports.SecurityEventLogger = exports.BusinessEventLogger = exports.ExampleRepository = exports.ExampleController = exports.ExampleService = void 0;
const LoggerConfig_1 = require("../LoggerConfig");
const CustomizedError_1 = __importDefault(require("../../classes/CustomizedError"));
// ============================================================================
// EJEMPLO 1: Logging en Servicios
// ============================================================================
class ExampleService {
    serviceLogger = LoggerConfig_1.logger.child({ module: 'ExampleService' });
    async createUser(userData) {
        this.serviceLogger.info('Creating new user', {
            function: 'createUser',
        }, {
            email: userData.email, // No incluir password
            role: userData.role,
        });
        try {
            // Simular operación de base de datos
            const startTime = Date.now();
            // ... lógica de creación
            const duration = Date.now() - startTime;
            this.serviceLogger.logDatabaseQuery('INSERT INTO users (email, role) VALUES ($1, $2)', duration, { function: 'createUser' });
            this.serviceLogger.logBusinessEvent('user_created', {
                function: 'createUser',
            }, {
                userId: 123,
                email: userData.email,
                role: userData.role,
            });
            return { id: 123, email: userData.email };
        }
        catch (error) {
            this.serviceLogger.error('Failed to create user', error, { function: 'createUser' }, { userData: { email: userData.email, role: userData.role } });
            throw error;
        }
    }
    async authenticateUser(email, password) {
        this.serviceLogger.info('User authentication attempt', {
            function: 'authenticateUser',
        }, {
            email, // No incluir password en logs
        });
        try {
            // ... lógica de autenticación
            if (false /* authentication failed */) {
                this.serviceLogger.logSecurityEvent('failed_login_attempt', {
                    function: 'authenticateUser',
                }, {
                    email,
                    reason: 'invalid_credentials',
                });
                throw new CustomizedError_1.default('Credenciales inválidas', 401);
            }
            this.serviceLogger.logSecurityEvent('successful_login', {
                function: 'authenticateUser',
            }, {
                email,
                userId: 123,
            });
            return { userId: 123, token: 'jwt_token_here' };
        }
        catch (error) {
            if (error instanceof CustomizedError_1.default) {
                // Los errores esperados se loggean como warnings
                this.serviceLogger.warn(`Authentication failed: ${error.message}`, { function: 'authenticateUser' }, { email });
            }
            else {
                // Errores inesperados se loggean como errores
                this.serviceLogger.error('Unexpected error during authentication', error, { function: 'authenticateUser' }, { email });
            }
            throw error;
        }
    }
}
exports.ExampleService = ExampleService;
// ============================================================================
// EJEMPLO 2: Logging en Controladores
// ============================================================================
class ExampleController {
    exampleService;
    constructor(exampleService) {
        this.exampleService = exampleService;
    }
    createUser = async (req, res, next) => {
        // Usar el logger del request que incluye contexto automático
        req.logger?.info('Processing user creation request', {
            module: 'ExampleController',
            function: 'createUser',
        });
        try {
            const user = await this.exampleService.createUser(req.body);
            req.logger?.info('User created successfully', {
                module: 'ExampleController',
                function: 'createUser',
            }, {
                userId: user.id,
            });
            res.status(201).json(user);
        }
        catch (error) {
            // El middleware de error se encargará del logging
            next(error);
        }
    };
    login = async (req, res, next) => {
        req.logger?.info('Processing login request', {
            module: 'ExampleController',
            function: 'login',
        });
        try {
            const { email, password } = req.body;
            const result = await this.exampleService.authenticateUser(email, password);
            req.logger?.info('Login successful', {
                module: 'ExampleController',
                function: 'login',
            });
            res.json(result);
        }
        catch (error) {
            next(error);
        }
    };
}
exports.ExampleController = ExampleController;
// ============================================================================
// EJEMPLO 3: Logging en Repositorios
// ============================================================================
class ExampleRepository {
    repoLogger = LoggerConfig_1.logger.child({ module: 'ExampleRepository' });
    async findUserById(id) {
        const startTime = Date.now();
        try {
            // Simular consulta a base de datos
            const query = 'SELECT * FROM users WHERE id = $1';
            // ... ejecutar consulta
            const duration = Date.now() - startTime;
            this.repoLogger.logDatabaseQuery(query, duration, {
                function: 'findUserById',
            });
            return { id, email: 'user@example.com' };
        }
        catch (error) {
            const duration = Date.now() - startTime;
            this.repoLogger.error('Database query failed', error, {
                function: 'findUserById',
                responseTime: duration,
            }, {
                query: 'SELECT * FROM users WHERE id = $1',
                parameters: { id },
            });
            throw error;
        }
    }
    async createUser(userData) {
        const startTime = Date.now();
        this.repoLogger.debug('Executing user creation query', {
            function: 'createUser',
        });
        try {
            // ... lógica de creación
            const duration = Date.now() - startTime;
            this.repoLogger.logDatabaseQuery('INSERT INTO users (email, role) VALUES ($1, $2) RETURNING *', duration, { function: 'createUser' });
            return { id: 123, ...userData };
        }
        catch (error) {
            const duration = Date.now() - startTime;
            // Detectar errores específicos de base de datos
            if (error.code === '23505') { // Unique violation
                this.repoLogger.warn('User creation failed: email already exists', {
                    function: 'createUser',
                    responseTime: duration,
                }, { email: userData.email });
            }
            else {
                this.repoLogger.error('Unexpected database error during user creation', error, {
                    function: 'createUser',
                    responseTime: duration,
                }, { userData });
            }
            throw error;
        }
    }
}
exports.ExampleRepository = ExampleRepository;
// ============================================================================
// EJEMPLO 4: Logging de Eventos de Negocio
// ============================================================================
class BusinessEventLogger {
    static logPaymentProcessed(paymentData) {
        LoggerConfig_1.logger.logBusinessEvent('payment_processed', {
            module: 'payments',
        }, {
            paymentId: paymentData.id,
            amount: paymentData.amount,
            method: paymentData.method,
            userId: paymentData.userId,
        });
    }
    static logClassScheduled(classData) {
        LoggerConfig_1.logger.logBusinessEvent('driving_class_scheduled', {
            module: 'classes',
        }, {
            classId: classData.id,
            studentId: classData.studentId,
            instructorId: classData.instructorId,
            date: classData.date,
        });
    }
    static logInstructorValidated(instructorData) {
        LoggerConfig_1.logger.logBusinessEvent('instructor_validated', {
            module: 'instructors',
        }, {
            instructorId: instructorData.id,
            userId: instructorData.userId,
            validatedBy: instructorData.validatedBy,
        });
    }
}
exports.BusinessEventLogger = BusinessEventLogger;
// ============================================================================
// EJEMPLO 5: Logging de Eventos de Seguridad
// ============================================================================
class SecurityEventLogger {
    static logSuspiciousActivity(req, reason) {
        LoggerConfig_1.logger.logSecurityEvent('suspicious_activity', {
            ip: req.ip,
            userAgent: req.headers['user-agent'],
            userId: req.user?.id,
        }, {
            reason,
            url: req.originalUrl,
            method: req.method,
        });
    }
    static logPasswordChange(userId, ip) {
        LoggerConfig_1.logger.logSecurityEvent('password_changed', {
            userId,
            ip,
            module: 'auth',
        });
    }
    static logAccountLocked(userId, reason) {
        LoggerConfig_1.logger.logSecurityEvent('account_locked', {
            userId,
            module: 'auth',
        }, {
            reason,
            timestamp: new Date().toISOString(),
        });
    }
}
exports.SecurityEventLogger = SecurityEventLogger;
// ============================================================================
// EJEMPLO 6: Logging con Correlación de Requests
// ============================================================================
class CorrelatedLoggingExample {
    async processComplexOperation(req) {
        const operationLogger = req.logger?.child({
            operation: 'complex_operation',
            operationId: `op_${Date.now()}`,
        });
        operationLogger?.info('Starting complex operation');
        try {
            // Paso 1
            operationLogger?.debug('Step 1: Validating input');
            await this.validateInput(req.body);
            operationLogger?.debug('Step 1 completed');
            // Paso 2
            operationLogger?.debug('Step 2: Processing data');
            const processedData = await this.processData(req.body);
            operationLogger?.debug('Step 2 completed', undefined, {
                processedItems: processedData.length
            });
            // Paso 3
            operationLogger?.debug('Step 3: Saving to database');
            const result = await this.saveToDatabase(processedData);
            operationLogger?.debug('Step 3 completed');
            operationLogger?.info('Complex operation completed successfully', undefined, {
                resultId: result.id,
                itemsProcessed: processedData.length,
            });
            return result;
        }
        catch (error) {
            operationLogger?.error('Complex operation failed', error, undefined, { inputData: req.body });
            throw error;
        }
    }
    async validateInput(data) {
        // Simular validación
    }
    async processData(data) {
        // Simular procesamiento
        return [1, 2, 3];
    }
    async saveToDatabase(data) {
        // Simular guardado
        return { id: 123 };
    }
}
exports.CorrelatedLoggingExample = CorrelatedLoggingExample;
