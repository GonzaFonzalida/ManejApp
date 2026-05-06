-- AlterTable
ALTER TABLE "User" ADD COLUMN "apple_sub" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "User_apple_sub_key" ON "User"("apple_sub");
