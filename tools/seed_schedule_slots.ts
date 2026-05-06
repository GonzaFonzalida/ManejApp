import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log("📅 Creating schedule slots for demo...");

    // Get all instructors
    const instructors = await prisma.instructor.findMany({
        where: { isListed: true }
    });

    if (instructors.length === 0) {
        console.log("⚠️  No instructors found.");
        return;
    }

    const now = new Date();
    let totalCreated = 0;

    for (const instructor of instructors) {
        console.log(`Creating slots for Instructor ID: ${instructor.id}`);

        // Create 10 slots for each instructor (next 10 days, 10am-11am)
        for (let i = 1; i <= 10; i++) {
            const startTime = new Date(now);
            startTime.setDate(now.getDate() + i);
            startTime.setHours(10, 0, 0, 0);

            const endTime = new Date(startTime);
            endTime.setHours(11, 0, 0, 0);

            await prisma.scheduleSlot.create({
                data: {
                    instructorId: instructor.id,
                    startTime,
                    endTime,
                    status: 'AVAILABLE'
                }
            });
            totalCreated++;
        }
    }

    console.log(`✅ Created ${totalCreated} schedule slots for ${instructors.length} instructors.`);
}

main()
    .catch(e => console.error(e))
    .finally(async () => {
        await prisma.$disconnect();
    });
