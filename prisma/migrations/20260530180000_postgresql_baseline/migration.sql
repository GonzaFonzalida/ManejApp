-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "public"."InstructorDocumentReviewStatus" AS ENUM ('MISSING', 'PENDING_REVIEW', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "public"."MpConnectionStatus" AS ENUM ('PENDING', 'CONNECTED', 'DISCONNECTED');

-- CreateEnum
CREATE TYPE "public"."Role" AS ENUM ('STUDENT', 'INSTRUCTOR', 'ADMIN');

-- CreateEnum
CREATE TYPE "public"."Transmission" AS ENUM ('MANUAL', 'AUTOMATIC');

-- CreateEnum
CREATE TYPE "public"."SlotStatus" AS ENUM ('AVAILABLE', 'HELD', 'BOOKED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "public"."BookingStatus" AS ENUM ('PENDING_PAYMENT', 'CONFIRMED', 'CANCELLED', 'COMPLETED');

-- CreateTable
CREATE TABLE "public"."User" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "surname" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "dni" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "birthDate" TIMESTAMP(3) NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "role" "public"."Role" NOT NULL DEFAULT 'STUDENT',
    "lastLoginAt" TIMESTAMP(3),
    "emailVerificationToken" TEXT,
    "emailVerifiedAt" TIMESTAMP(3),
    "emailNotifications" BOOLEAN NOT NULL DEFAULT true,
    "pushNotifications" BOOLEAN NOT NULL DEFAULT true,
    "profile_image" TEXT,
    "phone_number" TEXT,
    "location" TEXT,
    "password_reset_token" TEXT,
    "password_reset_expires_at" TIMESTAMP(3),
    "google_id" TEXT,
    "apple_sub" TEXT,
    "account_deleted_at" TIMESTAMP(3),

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Session" (
    "id" TEXT NOT NULL,
    "userId" INTEGER NOT NULL,
    "refreshHash" TEXT NOT NULL,
    "userAgent" TEXT,
    "ip" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Student" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "experienceLevel" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "Student_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Car" (
    "id" SERIAL NOT NULL,
    "brand" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "licensePlate" TEXT NOT NULL,
    "transmission" "public"."Transmission" NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "instructorId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Car_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."InstructorDocumentReview" (
    "id" SERIAL NOT NULL,
    "instructorId" INTEGER NOT NULL,
    "documentType" TEXT NOT NULL,
    "status" "public"."InstructorDocumentReviewStatus" NOT NULL DEFAULT 'MISSING',
    "rejectionReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "InstructorDocumentReview_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Instructor" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "licenseNumber" TEXT,
    "experienceYears" INTEGER NOT NULL,
    "available" BOOLEAN NOT NULL DEFAULT true,
    "isValid" BOOLEAN NOT NULL DEFAULT false,
    "mp_collector_id" TEXT,
    "mp_access_token" TEXT,
    "mp_refresh_token" TEXT,
    "mp_public_key" TEXT,
    "mp_token_type" TEXT,
    "mp_scope" TEXT,
    "mp_token_expires_at" TIMESTAMP(3),
    "mp_connected_at" TIMESTAMP(3),
    "mp_disconnected_at" TIMESTAMP(3),
    "mp_connection_status" "public"."MpConnectionStatus" NOT NULL DEFAULT 'DISCONNECTED',
    "mp_oauth_state" TEXT,
    "mp_oauth_state_expires_at" TIMESTAMP(3),
    "commission_rate" DOUBLE PRECISION NOT NULL DEFAULT 20,
    "hourly_rate" DOUBLE PRECISION,
    "doble_comando_img" TEXT,
    "seguro_img" TEXT,
    "vtv_img" TEXT,
    "reincidencia_img" TEXT,
    "licencia_img" TEXT,
    "bio" TEXT,
    "categories" JSONB,
    "photos" JSONB,
    "is_listed" BOOLEAN NOT NULL DEFAULT false,
    "validity_suspended_by_admin" BOOLEAN NOT NULL DEFAULT false,
    "lat" DOUBLE PRECISION,
    "lng" DOUBLE PRECISION,
    "geohash" TEXT,
    "address_text" TEXT,

    CONSTRAINT "Instructor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Admin" (
    "id" INTEGER NOT NULL,
    "companyName" TEXT NOT NULL,

    CONSTRAINT "Admin_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Permission" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "isMandatory" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "Permission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."InstructorPermission" (
    "instructorId" INTEGER NOT NULL,
    "permissionId" INTEGER NOT NULL,
    "granted" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "InstructorPermission_pkey" PRIMARY KEY ("instructorId","permissionId")
);

-- CreateTable
CREATE TABLE "public"."DrivingClass" (
    "id" SERIAL NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "duration" INTEGER NOT NULL,
    "status" "public"."BookingStatus" NOT NULL DEFAULT 'PENDING_PAYMENT',
    "notes" TEXT,
    "studentId" INTEGER NOT NULL,
    "instructorId" INTEGER NOT NULL,
    "amount" DOUBLE PRECISION,
    "currency" TEXT DEFAULT 'ARS',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "class_reminder_sent_at" TIMESTAMP(3),

    CONSTRAINT "DrivingClass_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Payment" (
    "id" SERIAL NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "paymentMethod" TEXT NOT NULL,
    "provider" TEXT DEFAULT 'mercadopago',
    "drivingClassId" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "externalReference" TEXT,
    "paymentId" TEXT,
    "preferenceId" TEXT,
    "idempotency_key" TEXT,
    "last_recovery_at" TIMESTAMP(3),
    "recovery_attempts" INTEGER NOT NULL DEFAULT 0,
    "raw_payload" JSONB,
    "app_commission" DOUBLE PRECISION,
    "instructor_amount" DOUBLE PRECISION,
    "commission_rate" DOUBLE PRECISION,
    "mp_transaction_amount" DOUBLE PRECISION,
    "instructor_payout_status" TEXT NOT NULL DEFAULT 'not_applicable',
    "instructor_payout_eligible_at" TIMESTAMP(3),
    "mp_collector_id" TEXT,
    "marketplace_fee" DOUBLE PRECISION,
    "preference_init_point" TEXT,
    "preference_sandbox_init_point" TEXT,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ScheduleSlot" (
    "id" TEXT NOT NULL,
    "instructorId" INTEGER NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "status" "public"."SlotStatus" NOT NULL DEFAULT 'AVAILABLE',
    "held_until" TIMESTAMP(3),
    "drivingClassId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ScheduleSlot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."NotificationToken" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "token" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "NotificationToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."payment_recovery_logs" (
    "id" SERIAL NOT NULL,
    "payment_id" INTEGER NOT NULL,
    "step" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "data" TEXT DEFAULT '{}',
    "error" TEXT,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "payment_recovery_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."blacklisted_tokens" (
    "id" SERIAL NOT NULL,
    "jti" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "blacklisted_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Conversation" (
    "id" SERIAL NOT NULL,
    "participant1Id" INTEGER NOT NULL,
    "participant2Id" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Conversation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Message" (
    "id" SERIAL NOT NULL,
    "conversationId" INTEGER NOT NULL,
    "senderId" INTEGER NOT NULL,
    "content" TEXT NOT NULL,
    "sentAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "readAt" TIMESTAMP(3),

    CONSTRAINT "Message_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SystemConfig" (
    "id" SERIAL NOT NULL,
    "reportInterval" TEXT NOT NULL DEFAULT 'weekly',
    "reportEmails" TEXT NOT NULL DEFAULT '',
    "errorAlertsEnabled" BOOLEAN NOT NULL DEFAULT true,
    "lastReportSent" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SystemConfig_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "public"."User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_dni_key" ON "public"."User"("dni");

-- CreateIndex
CREATE UNIQUE INDEX "User_emailVerificationToken_key" ON "public"."User"("emailVerificationToken");

-- CreateIndex
CREATE UNIQUE INDEX "User_password_reset_token_key" ON "public"."User"("password_reset_token");

-- CreateIndex
CREATE UNIQUE INDEX "User_google_id_key" ON "public"."User"("google_id");

-- CreateIndex
CREATE UNIQUE INDEX "User_apple_sub_key" ON "public"."User"("apple_sub");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "public"."User"("role");

-- CreateIndex
CREATE UNIQUE INDEX "Session_refreshHash_key" ON "public"."Session"("refreshHash");

-- CreateIndex
CREATE INDEX "Session_userId_idx" ON "public"."Session"("userId");

-- CreateIndex
CREATE INDEX "Session_expiresAt_idx" ON "public"."Session"("expiresAt");

-- CreateIndex
CREATE UNIQUE INDEX "Student_userId_key" ON "public"."Student"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Car_licensePlate_key" ON "public"."Car"("licensePlate");

-- CreateIndex
CREATE INDEX "Car_instructorId_idx" ON "public"."Car"("instructorId");

-- CreateIndex
CREATE INDEX "Car_isActive_idx" ON "public"."Car"("isActive");

-- CreateIndex
CREATE INDEX "InstructorDocumentReview_instructorId_idx" ON "public"."InstructorDocumentReview"("instructorId");

-- CreateIndex
CREATE UNIQUE INDEX "InstructorDocumentReview_instructorId_documentType_key" ON "public"."InstructorDocumentReview"("instructorId", "documentType");

-- CreateIndex
CREATE UNIQUE INDEX "Instructor_userId_key" ON "public"."Instructor"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Instructor_mp_oauth_state_key" ON "public"."Instructor"("mp_oauth_state");

-- CreateIndex
CREATE INDEX "Instructor_mp_collector_id_idx" ON "public"."Instructor"("mp_collector_id");

-- CreateIndex
CREATE INDEX "Instructor_is_listed_idx" ON "public"."Instructor"("is_listed");

-- CreateIndex
CREATE INDEX "Instructor_lat_lng_idx" ON "public"."Instructor"("lat", "lng");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_idempotency_key_key" ON "public"."Payment"("idempotency_key");

-- CreateIndex
CREATE INDEX "Payment_idempotency_key_idx" ON "public"."Payment"("idempotency_key");

-- CreateIndex
CREATE INDEX "Payment_externalReference_idx" ON "public"."Payment"("externalReference");

-- CreateIndex
CREATE INDEX "Payment_status_idx" ON "public"."Payment"("status");

-- CreateIndex
CREATE UNIQUE INDEX "ScheduleSlot_drivingClassId_key" ON "public"."ScheduleSlot"("drivingClassId");

-- CreateIndex
CREATE INDEX "ScheduleSlot_instructorId_idx" ON "public"."ScheduleSlot"("instructorId");

-- CreateIndex
CREATE INDEX "ScheduleSlot_startTime_endTime_idx" ON "public"."ScheduleSlot"("startTime", "endTime");

-- CreateIndex
CREATE INDEX "ScheduleSlot_status_idx" ON "public"."ScheduleSlot"("status");

-- CreateIndex
CREATE UNIQUE INDEX "NotificationToken_userId_key" ON "public"."NotificationToken"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "NotificationToken_token_key" ON "public"."NotificationToken"("token");

-- CreateIndex
CREATE INDEX "NotificationToken_userId_idx" ON "public"."NotificationToken"("userId");

-- CreateIndex
CREATE INDEX "payment_recovery_logs_payment_id_idx" ON "public"."payment_recovery_logs"("payment_id");

-- CreateIndex
CREATE INDEX "payment_recovery_logs_timestamp_idx" ON "public"."payment_recovery_logs"("timestamp");

-- CreateIndex
CREATE INDEX "payment_recovery_logs_status_idx" ON "public"."payment_recovery_logs"("status");

-- CreateIndex
CREATE UNIQUE INDEX "blacklisted_tokens_jti_key" ON "public"."blacklisted_tokens"("jti");

-- CreateIndex
CREATE INDEX "blacklisted_tokens_jti_idx" ON "public"."blacklisted_tokens"("jti");

-- CreateIndex
CREATE INDEX "blacklisted_tokens_expires_at_idx" ON "public"."blacklisted_tokens"("expires_at");

-- CreateIndex
CREATE INDEX "Conversation_participant1Id_idx" ON "public"."Conversation"("participant1Id");

-- CreateIndex
CREATE INDEX "Conversation_participant2Id_idx" ON "public"."Conversation"("participant2Id");

-- CreateIndex
CREATE UNIQUE INDEX "Conversation_participant1Id_participant2Id_key" ON "public"."Conversation"("participant1Id", "participant2Id");

-- CreateIndex
CREATE INDEX "Message_conversationId_idx" ON "public"."Message"("conversationId");

-- CreateIndex
CREATE INDEX "Message_senderId_idx" ON "public"."Message"("senderId");

-- CreateIndex
CREATE INDEX "Message_sentAt_idx" ON "public"."Message"("sentAt");

-- AddForeignKey
ALTER TABLE "public"."Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Student" ADD CONSTRAINT "Student_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Car" ADD CONSTRAINT "Car_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "public"."Instructor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."InstructorDocumentReview" ADD CONSTRAINT "InstructorDocumentReview_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "public"."Instructor"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Instructor" ADD CONSTRAINT "Instructor_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Admin" ADD CONSTRAINT "Admin_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."InstructorPermission" ADD CONSTRAINT "InstructorPermission_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "public"."Instructor"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."InstructorPermission" ADD CONSTRAINT "InstructorPermission_permissionId_fkey" FOREIGN KEY ("permissionId") REFERENCES "public"."Permission"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."DrivingClass" ADD CONSTRAINT "DrivingClass_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "public"."Instructor"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."DrivingClass" ADD CONSTRAINT "DrivingClass_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Payment" ADD CONSTRAINT "Payment_drivingClassId_fkey" FOREIGN KEY ("drivingClassId") REFERENCES "public"."DrivingClass"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ScheduleSlot" ADD CONSTRAINT "ScheduleSlot_drivingClassId_fkey" FOREIGN KEY ("drivingClassId") REFERENCES "public"."DrivingClass"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ScheduleSlot" ADD CONSTRAINT "ScheduleSlot_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "public"."Instructor"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."NotificationToken" ADD CONSTRAINT "NotificationToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Conversation" ADD CONSTRAINT "Conversation_participant1Id_fkey" FOREIGN KEY ("participant1Id") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Conversation" ADD CONSTRAINT "Conversation_participant2Id_fkey" FOREIGN KEY ("participant2Id") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Message" ADD CONSTRAINT "Message_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "public"."Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Message" ADD CONSTRAINT "Message_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
