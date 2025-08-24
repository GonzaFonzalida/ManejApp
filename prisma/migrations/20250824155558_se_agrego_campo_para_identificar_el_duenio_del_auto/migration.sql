/*
  Warnings:

  - You are about to drop the column `carId` on the `Instructor` table. All the data in the column will be lost.
  - Added the required column `instructorId` to the `Car` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "public"."Instructor" DROP CONSTRAINT "Instructor_carId_fkey";

-- DropIndex
DROP INDEX "public"."Instructor_carId_key";

-- AlterTable
ALTER TABLE "public"."Car" ADD COLUMN     "instructorId" INTEGER NOT NULL;

-- AlterTable
ALTER TABLE "public"."Instructor" DROP COLUMN "carId";

-- AddForeignKey
ALTER TABLE "public"."Car" ADD CONSTRAINT "Car_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "public"."Instructor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
