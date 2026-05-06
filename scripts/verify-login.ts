import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

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

    const isMatch = await bcrypt.compare(password, user.password);
    console.log(`Password '123456' match result: ${isMatch}`);

    if (isMatch) {
        console.log('SUCCESS: Credentials are valid in the DB.');
    } else {
        console.error('FAILURE: Hash mismatch.');
        // Let's try to generate a new hash and see
        const newHash = await bcrypt.hash(password, 10);
        console.log('New Hash would be:', newHash);
    }
}

main()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
