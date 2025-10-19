-- CreateTable
CREATE TABLE "public"."ScheduleSlot" (
    "id" TEXT NOT NULL,
    "instructorId" INTEGER NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "isBooked" BOOLEAN NOT NULL DEFAULT false,
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

-- CreateIndex
CREATE UNIQUE INDEX "ScheduleSlot_drivingClassId_key" ON "public"."ScheduleSlot"("drivingClassId");

-- CreateIndex
CREATE INDEX "ScheduleSlot_instructorId_idx" ON "public"."ScheduleSlot"("instructorId");

-- CreateIndex
CREATE INDEX "ScheduleSlot_startTime_endTime_idx" ON "public"."ScheduleSlot"("startTime", "endTime");

-- CreateIndex
CREATE UNIQUE INDEX "NotificationToken_userId_key" ON "public"."NotificationToken"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "NotificationToken_token_key" ON "public"."NotificationToken"("token");

-- CreateIndex
CREATE INDEX "NotificationToken_userId_idx" ON "public"."NotificationToken"("userId");

-- AddForeignKey
ALTER TABLE "public"."ScheduleSlot" ADD CONSTRAINT "ScheduleSlot_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "public"."Instructor"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ScheduleSlot" ADD CONSTRAINT "ScheduleSlot_drivingClassId_fkey" FOREIGN KEY ("drivingClassId") REFERENCES "public"."DrivingClass"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."NotificationToken" ADD CONSTRAINT "NotificationToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
