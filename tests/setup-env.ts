import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

// Load env vars first (to ensure other config is present)
dotenv.config({ path: '.env.test' });

const urlFile = path.join(__dirname, 'test-db-url.txt');
if (fs.existsSync(urlFile)) {
    const url = fs.readFileSync(urlFile, 'utf-8').trim();
    process.env.DATABASE_URL = url;
}
