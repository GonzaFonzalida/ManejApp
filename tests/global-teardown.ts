import fs from 'fs';
import path from 'path';

export default async () => {
    console.log('Tearing down Test Environment...');

    const dbPath = path.join(__dirname, '../prisma/test.db');

    // Cleanup database file
    if (fs.existsSync(dbPath)) {
        fs.unlinkSync(dbPath);
    }

    // Cleanup URL file
    const urlFile = path.join(__dirname, 'test-db-url.txt');
    if (fs.existsSync(urlFile)) {
        fs.unlinkSync(urlFile);
    }
};
