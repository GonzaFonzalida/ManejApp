/*
  Warnings:

  - You are about to drop the column `userId` on the `Admin` table. All the data in the column will be lost.
  - Made the column `description` on table `Permission` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "public"."Admin" DROP CONSTRAINT "Admin_userId_fkey";

-- DropIndex
DROP INDEX "public"."Admin_userId_key";

-- AlterTable
ALTER TABLE "public"."Admin" DROP COLUMN "userId",
ALTER COLUMN "id" DROP DEFAULT;
DROP SEQUENCE "Admin_id_seq";

-- AlterTable
ALTER TABLE "public"."Permission" ALTER COLUMN "description" SET NOT NULL;

-- AddForeignKey
ALTER TABLE "public"."Admin" ADD CONSTRAINT "Admin_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
