-- Fase 2: trazabilidad marketplace en Payment
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "mp_collector_id" TEXT;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "marketplace_fee" DOUBLE PRECISION;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "preference_init_point" TEXT;
ALTER TABLE "Payment" ADD COLUMN IF NOT EXISTS "preference_sandbox_init_point" TEXT;
