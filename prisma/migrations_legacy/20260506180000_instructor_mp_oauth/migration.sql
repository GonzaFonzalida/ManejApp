-- CreateEnum
CREATE TYPE "MpConnectionStatus" AS ENUM ('PENDING', 'CONNECTED', 'DISCONNECTED');

-- AlterTable
ALTER TABLE "Instructor"
ADD COLUMN "mp_refresh_token" TEXT,
ADD COLUMN "mp_public_key" TEXT,
ADD COLUMN "mp_token_type" TEXT,
ADD COLUMN "mp_scope" TEXT,
ADD COLUMN "mp_token_expires_at" TIMESTAMP(3),
ADD COLUMN "mp_connected_at" TIMESTAMP(3),
ADD COLUMN "mp_disconnected_at" TIMESTAMP(3),
ADD COLUMN "mp_connection_status" "MpConnectionStatus" NOT NULL DEFAULT 'DISCONNECTED',
ADD COLUMN "mp_oauth_state" TEXT,
ADD COLUMN "mp_oauth_state_expires_at" TIMESTAMP(3);

-- CreateIndex
CREATE UNIQUE INDEX "Instructor_mp_oauth_state_key" ON "Instructor"("mp_oauth_state");
