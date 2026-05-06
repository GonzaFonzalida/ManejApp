import { clearDatabase } from '../tests/helpers/db-cleaner';
import { prisma } from '../src/config/prismaClient';

async function main() {
    console.log('🗑️  Clearing database...');
    await clearDatabase();
    console.log('✅ Database cleared successfully.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
