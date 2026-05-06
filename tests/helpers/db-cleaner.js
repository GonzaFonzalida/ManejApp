"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clearDatabase = void 0;
const prismaClient_1 = require("../../src/config/prismaClient");
const clearDatabase = async () => {
    // Delete in order of dependencies (child first)
    // Level 4: Deep dependencies
    await prismaClient_1.prisma.paymentRecoveryLog.deleteMany();
    // Level 3: Dependencies of DrivingClass/Instructor
    await prismaClient_1.prisma.payment.deleteMany();
    await prismaClient_1.prisma.scheduleSlot.deleteMany();
    await prismaClient_1.prisma.car.deleteMany();
    await prismaClient_1.prisma.instructorPermission.deleteMany();
    // Level 2: Core Domain Entities
    await prismaClient_1.prisma.drivingClass.deleteMany();
    await prismaClient_1.prisma.instructor.deleteMany();
    await prismaClient_1.prisma.student.deleteMany();
    // Level 1: User related
    await prismaClient_1.prisma.session.deleteMany();
    await prismaClient_1.prisma.notificationToken.deleteMany();
    await prismaClient_1.prisma.message.deleteMany();
    await prismaClient_1.prisma.conversation.deleteMany();
    await prismaClient_1.prisma.blacklistedToken.deleteMany();
    await prismaClient_1.prisma.admin.deleteMany();
    // Level 0: Root
    await prismaClient_1.prisma.user.deleteMany();
};
exports.clearDatabase = clearDatabase;
