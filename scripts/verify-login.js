"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const prisma = new client_1.PrismaClient();
async function main() {
    const email = 'student@test.com';
    const password = '123456';
    console.log(`Verifying user: ${email}`);
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
        console.error('User NOT found in database!');
        return;
    }
    console.log('User found. Role:', user.role);
    console.log('Stored Hash:', user.password);
    const isMatch = await bcryptjs_1.default.compare(password, user.password);
    console.log(`Password '123456' match result: ${isMatch}`);
    if (isMatch) {
        console.log('SUCCESS: Credentials are valid in the DB.');
    }
    else {
        console.error('FAILURE: Hash mismatch.');
        // Let's try to generate a new hash and see
        const newHash = await bcryptjs_1.default.hash(password, 10);
        console.log('New Hash would be:', newHash);
    }
}
main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
