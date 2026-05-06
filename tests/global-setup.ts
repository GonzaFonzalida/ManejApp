import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

export default async () => {
    console.log('Setting up Test Environment (SQLite)...');

    // Define test database path
    const dbPath = path.join(__dirname, '../prisma/test.db');
    const dbUrl = `file:${dbPath}`;

    // Ensure clean slate
    if (fs.existsSync(dbPath)) {
        fs.unlinkSync(dbPath);
    }

    // Set env var for migration command
    process.env.DATABASE_URL = dbUrl;

    console.log('Running migrations on test database...');
    try {
        // Use prisma db push for SQLite to quickly sync schema without migration history friction in tests
        execSync(`DATABASE_URL="${dbUrl}" npx prisma db push --accept-data-loss`, { stdio: 'inherit' });
    } catch (err) {
        console.error('Failed to run migrations', err);
        process.exit(1);
    }

    // Write URL to file for workers
    fs.writeFileSync(path.join(__dirname, 'test-db-url.txt'), dbUrl);
};
