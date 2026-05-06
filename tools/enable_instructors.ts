import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log("🔓 Enabling all instructors for Demo...");
    const updated = await prisma.instructor.updateMany({
        data: {
            isListed: true,
            isValid: true,
            available: true
        }
    });
    console.log(`✅ Updated ${updated.count} instructors. They are now visible in the app.`);
}

main()
    .catch(e => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
