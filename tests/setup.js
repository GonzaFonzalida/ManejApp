"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const LoggerConfig_1 = require("@logging/LoggerConfig");
// Silence logs during tests by mocking the methods
beforeAll(() => {
    jest.spyOn(LoggerConfig_1.logger, 'info').mockImplementation(() => { });
    jest.spyOn(LoggerConfig_1.logger, 'error').mockImplementation(() => { });
    jest.spyOn(LoggerConfig_1.logger, 'warn').mockImplementation(() => { });
    jest.spyOn(LoggerConfig_1.logger, 'debug').mockImplementation(() => { });
    // Add other methods if necessary
    if (typeof LoggerConfig_1.logger.logRequest === 'function') {
        jest.spyOn(LoggerConfig_1.logger, 'logRequest').mockImplementation(() => { });
    }
});
afterAll(() => {
    jest.restoreAllMocks();
});
