/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
    // Una sola DB SQLite de test: evita carreras entre archivos de integración.
    maxWorkers: 1,
    preset: 'ts-jest',
    testEnvironment: 'node',
    transform: {
        '^.+\\.tsx?$': ['ts-jest', {
            tsconfig: 'tsconfig.test.json',
        }],
    },
    setupFiles: ['<rootDir>/tests/setup-env.ts'],
    setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
    globalSetup: '<rootDir>/tests/global-setup.ts',
    globalTeardown: '<rootDir>/tests/global-teardown.ts',
    moduleNameMapper: {
        '^@config/(.*)$': '<rootDir>/src/config/$1',
        '^@shared/(.*)$': '<rootDir>/src/shared/$1',
        '^@utils/(.*)$': '<rootDir>/src/shared/utils/$1',
        '^@sharedTypes/(.*)$': '<rootDir>/src/shared/types/$1',
        '^@classes/(.*)$': '<rootDir>/src/shared/classes/$1',
        '^@middlewares/(.*)$': '<rootDir>/src/shared/middlewares/$1',
        '^@logging/(.*)$': '<rootDir>/src/shared/logging/$1',
        '^@auth/(.*)$': '<rootDir>/src/modules/auth/$1',
        '^@users/(.*)$': '<rootDir>/src/modules/users/$1',
        '^@cars/(.*)$': '<rootDir>/src/modules/cars/$1',
        '^@instructors/(.*)$': '<rootDir>/src/modules/instructors/$1',
        '^@permissions/(.*)$': '<rootDir>/src/modules/permissions/$1',
        '^@drivingClass/(.*)$': '<rootDir>/src/modules/drivingClass/$1',
        '^@payments/(.*)$': '<rootDir>/src/modules/payments/$1',
        '^@schedule/(.*)$': '<rootDir>/src/modules/schedule/$1',
        '^@notifications/(.*)$': '<rootDir>/src/modules/notifications/$1'
    },
    testMatch: ['**/*.test.ts'],
    verbose: true,
    forceExit: true,
    clearMocks: true,
    resetMocks: true,
    restoreMocks: true,
};
