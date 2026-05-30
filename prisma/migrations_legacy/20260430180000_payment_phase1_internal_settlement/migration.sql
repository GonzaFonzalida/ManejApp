-- Fase 1 — cuenta única: conciliación MP vs pedido + estado liquidación interna instructor
ALTER TABLE "Payment" ADD COLUMN "mp_transaction_amount" DOUBLE PRECISION,
ADD COLUMN "instructor_payout_status" TEXT NOT NULL DEFAULT 'not_applicable',
ADD COLUMN "instructor_payout_eligible_at" TIMESTAMP(3);
