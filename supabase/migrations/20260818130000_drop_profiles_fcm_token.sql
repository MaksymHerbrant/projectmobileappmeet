-- ============================================================================
-- Drop the superseded profiles.fcm_token.
--
-- Tokens moved to user_devices in 20260816160000; the column was left in place
-- so the deployed clients kept working during the switch. Both the app and the
-- push function now read and write user_devices only, and one client path that
-- still wrote here has been corrected - so the column is dead weight sitting on
-- a table every authenticated user can read.
-- ============================================================================

ALTER TABLE "public"."profiles" DROP COLUMN IF EXISTS "fcm_token";
