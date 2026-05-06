-- Hace opcional `licenseNumber`: la verificación de licencia es por documento + revisión admin.
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Instructor" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "userId" INTEGER NOT NULL,
    "licenseNumber" TEXT,
    "experienceYears" INTEGER NOT NULL,
    "available" BOOLEAN NOT NULL DEFAULT true,
    "isValid" BOOLEAN NOT NULL DEFAULT false,
    "mp_collector_id" TEXT,
    "mp_access_token" TEXT,
    "commission_rate" REAL NOT NULL DEFAULT 80,
    "hourly_rate" REAL,
    "doble_comando_img" TEXT,
    "seguro_img" TEXT,
    "vtv_img" TEXT,
    "reincidencia_img" TEXT,
    "licencia_img" TEXT,
    "bio" TEXT,
    "categories" JSONB,
    "photos" JSONB,
    "is_listed" BOOLEAN NOT NULL DEFAULT false,
    "lat" REAL,
    "lng" REAL,
    "geohash" TEXT,
    "address_text" TEXT,
    "validity_suspended_by_admin" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "Instructor_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
INSERT INTO "new_Instructor" ("id", "userId", "licenseNumber", "experienceYears", "available", "isValid", "mp_collector_id", "mp_access_token", "commission_rate", "hourly_rate", "doble_comando_img", "seguro_img", "vtv_img", "reincidencia_img", "licencia_img", "bio", "categories", "photos", "is_listed", "lat", "lng", "geohash", "address_text", "validity_suspended_by_admin") SELECT "id", "userId", "licenseNumber", "experienceYears", "available", "isValid", "mp_collector_id", "mp_access_token", "commission_rate", "hourly_rate", "doble_comando_img", "seguro_img", "vtv_img", "reincidencia_img", "licencia_img", "bio", "categories", "photos", "is_listed", "lat", "lng", "geohash", "address_text", "validity_suspended_by_admin" FROM "Instructor";
DROP TABLE "Instructor";
ALTER TABLE "new_Instructor" RENAME TO "Instructor";
CREATE UNIQUE INDEX "Instructor_userId_key" ON "Instructor"("userId");
CREATE INDEX "Instructor_mp_collector_id_idx" ON "Instructor"("mp_collector_id");
CREATE INDEX "Instructor_is_listed_idx" ON "Instructor"("is_listed");
CREATE INDEX "Instructor_lat_lng_idx" ON "Instructor"("lat", "lng");
PRAGMA foreign_keys=ON;
