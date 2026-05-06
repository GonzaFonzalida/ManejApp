"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const child_process_1 = require("child_process");
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
exports.default = async () => {
    console.log('Setting up Test Environment (SQLite)...');
    // Define test database path
    const dbPath = path_1.default.join(__dirname, '../prisma/test.db');
    const dbUrl = `file:${dbPath}`;
    // Ensure clean slate
    if (fs_1.default.existsSync(dbPath)) {
        fs_1.default.unlinkSync(dbPath);
    }
    // Set env var for migration command
    process.env.DATABASE_URL = dbUrl;
    console.log('Running migrations on test database...');
    try {
        // Use prisma db push for SQLite to quickly sync schema without migration history friction in tests
        (0, child_process_1.execSync)(`DATABASE_URL="${dbUrl}" npx prisma db push --accept-data-loss`, { stdio: 'inherit' });
    }
    catch (err) {
        console.error('Failed to run migrations', err);
        process.exit(1);
    }
    // Write URL to file for workers
    fs_1.default.writeFileSync(path_1.default.join(__dirname, 'test-db-url.txt'), dbUrl);
};
