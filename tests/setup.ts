import { logger } from "@logging/LoggerConfig";

// Silence logs during tests by mocking the methods
beforeAll(() => {
    jest.spyOn(logger, 'info').mockImplementation(() => { });
    jest.spyOn(logger, 'error').mockImplementation(() => { });
    jest.spyOn(logger, 'warn').mockImplementation(() => { });
    jest.spyOn(logger, 'debug').mockImplementation(() => { });
    // Add other methods if necessary
    if (typeof logger.logRequest === 'function') {
        jest.spyOn(logger, 'logRequest').mockImplementation(() => { });
    }
});

afterAll(() => {
    jest.restoreAllMocks();
});
