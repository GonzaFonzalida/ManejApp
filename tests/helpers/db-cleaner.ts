import { prisma } from '../../src/config/prismaClient';

export const clearDatabase = async () => {
    // Delete in order of dependencies (child first)

    // Level 4: Deep dependencies
    await prisma.paymentRecoveryLog.deleteMany();

    // Level 3: Dependencies of DrivingClass/Instructor
    await prisma.payment.deleteMany();
    await prisma.scheduleSlot.deleteMany();
    await prisma.car.deleteMany();
    await prisma.instructorPermission.deleteMany();

    // Level 2: Core Domain Entities
    await prisma.drivingClass.deleteMany();
    await prisma.instructor.deleteMany();
    await prisma.student.deleteMany();

    // Level 1: User related
    await prisma.session.deleteMany();
    await prisma.notificationToken.deleteMany();
    await prisma.message.deleteMany();
    await prisma.conversation.deleteMany();
    await prisma.blacklistedToken.deleteMany();
    await prisma.admin.deleteMany();

    // Level 0: Root
    await prisma.user.deleteMany();
};
