-- ============================================================================
-- Move FCM tokens out of public.profiles
--
-- profiles is readable by every authenticated user (that is the point - it is
-- the matching feed), so storing fcm_token there handed every user the push
-- token of every other user. Column-level REVOKE is not an option because
-- PostgREST issues `select *` for a bare .select(), which would then fail.
--
-- Tokens move to their own table that nobody can read but the owner and the
-- service role. profiles.fcm_token is left in place for now so the currently
-- deployed Edge Function keeps working; it is dropped in a follow-up once the
-- new function and client are live.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."user_devices" (
    "profile_id" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    "fcm_token" "text" NOT NULL,
    "platform" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    PRIMARY KEY ("profile_id", "fcm_token")
);

ALTER TABLE "public"."user_devices" OWNER TO "postgres";
ALTER TABLE "public"."user_devices" ENABLE ROW LEVEL SECURITY;

-- No policy grants SELECT on anyone else's row. The service role bypasses RLS
-- and is the only thing that ever reads another user's token.
CREATE POLICY "user_devices_select_own" ON "public"."user_devices"
  FOR SELECT TO "authenticated"
  USING ("profile_id" = "auth"."uid"());

CREATE POLICY "user_devices_insert_own" ON "public"."user_devices"
  FOR INSERT TO "authenticated"
  WITH CHECK ("profile_id" = "auth"."uid"());

CREATE POLICY "user_devices_update_own" ON "public"."user_devices"
  FOR UPDATE TO "authenticated"
  USING ("profile_id" = "auth"."uid"())
  WITH CHECK ("profile_id" = "auth"."uid"());

CREATE POLICY "user_devices_delete_own" ON "public"."user_devices"
  FOR DELETE TO "authenticated"
  USING ("profile_id" = "auth"."uid"());

CREATE INDEX IF NOT EXISTS "user_devices_profile_id_idx" ON "public"."user_devices" ("profile_id");

-- Carry over the tokens that already exist.
INSERT INTO "public"."user_devices" ("profile_id", "fcm_token")
SELECT "id", "fcm_token"
FROM "public"."profiles"
WHERE "fcm_token" IS NOT NULL AND "fcm_token" <> ''
ON CONFLICT DO NOTHING;


-- ----------------------------------------------------------------------------
-- Who is allowed to trigger a push at whom.
--
-- Without this the send-push function would still be an open relay to any
-- user in the product: knowing a profile id would be enough to spam someone.
-- A push is only legitimate between two people who already share a room or a
-- like in either direction - which covers every case the app actually sends:
-- new like, mutual match, accepted request, chat message.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."can_notify"("p_sender" "uuid", "p_receiver" "uuid")
RETURNS boolean
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT
    "p_sender" IS DISTINCT FROM "p_receiver"
    AND (
      EXISTS (
        SELECT 1
        FROM "public"."room_participants" "a"
        JOIN "public"."room_participants" "b" ON "a"."room_id" = "b"."room_id"
        WHERE "a"."profile_id" = "p_sender" AND "b"."profile_id" = "p_receiver"
      )
      OR EXISTS (
        SELECT 1 FROM "public"."likes"
        WHERE ("sender_id" = "p_sender" AND "receiver_id" = "p_receiver")
           OR ("sender_id" = "p_receiver" AND "receiver_id" = "p_sender")
      )
    );
$$;

ALTER FUNCTION "public"."can_notify"("uuid", "uuid") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."can_notify"("uuid", "uuid") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."can_notify"("uuid", "uuid") TO "service_role";
