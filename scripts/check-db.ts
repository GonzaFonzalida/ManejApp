
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    const userCount = await prisma.user.count();
    console.log(`User count: ${userCount}`);

    const users = await prisma.user.findMany();
    console.log('Users:', JSON.stringify(users, null, 2));

    try {
        // Check SystemConfig
        const configCount = await (prisma as any).systemConfig.count();
        console.log(`SystemConfig count: ${configCount}`);
    } catch (e) {
        console.log('Error accessing SystemConfig:', e.message);
    }
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
