-- AlterTable
ALTER TABLE "public"."Payment" ADD COLUMN     "externalReference" TEXT,
ADD COLUMN     "paymentId" TEXT,
ADD COLUMN     "preferenceId" TEXT;
