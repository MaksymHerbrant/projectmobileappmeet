-- ============================================================================
-- RLS hardening + missing indexes
--
-- Before this migration:
--   * messages / rooms / room_participants had a single "Allow all for
--     authenticated" policy with USING (true). Any signed-up account could
--     read, edit and delete EVERY private conversation in the product.
--   * likes had two USING (true) policies, letting anyone read or delete
--     anyone else's matches.
--   * profiles was readable by the `anon` role, so the whole user table
--     (including phone numbers and FCM tokens) was reachable without login.
--   * The database had no secondary indexes at all — every lookup by
--     sender_id / room_id / user_id was a sequential scan.
--
-- This migration only changes policies, grants and indexes. It does not
-- modify, delete or move any row.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Helpers
--
-- Membership checks have to run as SECURITY DEFINER: a policy on
-- room_participants that queries room_participants would recurse and abort.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."is_room_member"("p_room_id" "uuid", "p_profile_id" "uuid")
RETURNS boolean
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT EXISTS (
    SELECT 1 FROM "public"."room_participants"
    WHERE "room_id" = "p_room_id" AND "profile_id" = "p_profile_id"
  );
$$;

-- A freshly inserted room has no participants yet; that is the only moment a
-- user is allowed to add rows for a room they are not already part of.
CREATE OR REPLACE FUNCTION "public"."room_is_empty"("p_room_id" "uuid")
RETURNS boolean
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM "public"."room_participants" WHERE "room_id" = "p_room_id"
  );
$$;

ALTER FUNCTION "public"."is_room_member"("uuid", "uuid") OWNER TO "postgres";
ALTER FUNCTION "public"."room_is_empty"("uuid") OWNER TO "postgres";

REVOKE ALL ON FUNCTION "public"."is_room_member"("uuid", "uuid") FROM PUBLIC;
REVOKE ALL ON FUNCTION "public"."room_is_empty"("uuid") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."is_room_member"("uuid", "uuid") TO "authenticated";
GRANT EXECUTE ON FUNCTION "public"."room_is_empty"("uuid") TO "authenticated";


-- ----------------------------------------------------------------------------
-- messages
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Allow all for authenticated" ON "public"."messages";

CREATE POLICY "messages_select_room_members" ON "public"."messages"
  FOR SELECT TO "authenticated"
  USING ("public"."is_room_member"("room_id", "auth"."uid"()));

CREATE POLICY "messages_insert_as_self" ON "public"."messages"
  FOR INSERT TO "authenticated"
  WITH CHECK (
    "sender_id" = "auth"."uid"()
    AND "public"."is_room_member"("room_id", "auth"."uid"())
  );

-- markMessagesAsRead() flips is_read on messages written by the other party,
-- so this cannot be narrowed to sender_id.
CREATE POLICY "messages_update_room_members" ON "public"."messages"
  FOR UPDATE TO "authenticated"
  USING ("public"."is_room_member"("room_id", "auth"."uid"()))
  WITH CHECK ("public"."is_room_member"("room_id", "auth"."uid"()));

CREATE POLICY "messages_delete_own" ON "public"."messages"
  FOR DELETE TO "authenticated"
  USING ("sender_id" = "auth"."uid"());


-- ----------------------------------------------------------------------------
-- rooms
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Allow all for authenticated" ON "public"."rooms";

CREATE POLICY "rooms_select_members" ON "public"."rooms"
  FOR SELECT TO "authenticated"
  USING ("public"."is_room_member"("id", "auth"."uid"()));

CREATE POLICY "rooms_insert_authenticated" ON "public"."rooms"
  FOR INSERT TO "authenticated"
  WITH CHECK (true);

-- sendMessage() writes last_message / last_message_time on the room.
CREATE POLICY "rooms_update_members" ON "public"."rooms"
  FOR UPDATE TO "authenticated"
  USING ("public"."is_room_member"("id", "auth"."uid"()))
  WITH CHECK ("public"."is_room_member"("id", "auth"."uid"()));


-- ----------------------------------------------------------------------------
-- room_participants
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Allow all for authenticated" ON "public"."room_participants";

CREATE POLICY "room_participants_select_members" ON "public"."room_participants"
  FOR SELECT TO "authenticated"
  USING ("public"."is_room_member"("room_id", "auth"."uid"()));

-- createPrivateChat() adds both sides right after creating an empty room;
-- addUserToEventChat() adds someone to a room the caller already belongs to.
CREATE POLICY "room_participants_insert_scoped" ON "public"."room_participants"
  FOR INSERT TO "authenticated"
  WITH CHECK (
    "public"."is_room_member"("room_id", "auth"."uid"())
    OR "public"."room_is_empty"("room_id")
  );

CREATE POLICY "room_participants_delete_self" ON "public"."room_participants"
  FOR DELETE TO "authenticated"
  USING ("profile_id" = "auth"."uid"());


-- ----------------------------------------------------------------------------
-- likes
--
-- The two blanket policies are dropped. The pre-existing scoped policies
-- (insert as sender, select as sender-or-receiver, update as receiver) stay;
-- the sender-side update and the delete path are added here because
-- acceptLike() upserts as the sender and rejectLike() deletes.
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Enable all for authenticated" ON "public"."likes";
DROP POLICY IF EXISTS "public_likes_policy" ON "public"."likes";

CREATE POLICY "likes_update_sender" ON "public"."likes"
  FOR UPDATE TO "authenticated"
  USING ("auth"."uid"() = "sender_id")
  WITH CHECK ("auth"."uid"() = "sender_id");

CREATE POLICY "likes_delete_participants" ON "public"."likes"
  FOR DELETE TO "authenticated"
  USING ("auth"."uid"() = "receiver_id" OR "auth"."uid"() = "sender_id");


-- ----------------------------------------------------------------------------
-- profiles
--
-- "Public profiles are viewable by everyone" had no role restriction, so it
-- also granted the anon role a full table read. Dropped. Two further policies
-- are exact duplicates of ones that remain, and only add planner work.
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON "public"."profiles";
DROP POLICY IF EXISTS "Users can read their own profile." ON "public"."profiles";
DROP POLICY IF EXISTS "Users can update their own profile." ON "public"."profiles";


-- ----------------------------------------------------------------------------
-- events
--
-- "Public events are visible" also covered the anon role.
-- Creators additionally had no way to edit or delete their own events.
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Public events are visible" ON "public"."events";

CREATE POLICY "events_select_authenticated" ON "public"."events"
  FOR SELECT TO "authenticated"
  USING (true);

CREATE POLICY "events_update_own" ON "public"."events"
  FOR UPDATE TO "authenticated"
  USING ("auth"."uid"() = "creator_id")
  WITH CHECK ("auth"."uid"() = "creator_id");

CREATE POLICY "events_delete_own" ON "public"."events"
  FOR DELETE TO "authenticated"
  USING ("auth"."uid"() = "creator_id");


-- ----------------------------------------------------------------------------
-- event_likes
--
-- recordEventSwipe() upserts, which needs an UPDATE path.
-- ----------------------------------------------------------------------------

CREATE POLICY "event_likes_update_own" ON "public"."event_likes"
  FOR UPDATE TO "authenticated"
  USING ("auth"."uid"() = "user_id")
  WITH CHECK ("auth"."uid"() = "user_id");

CREATE POLICY "event_likes_delete_own" ON "public"."event_likes"
  FOR DELETE TO "authenticated"
  USING ("auth"."uid"() = "user_id");


-- ----------------------------------------------------------------------------
-- Indexes
--
-- Postgres does not create indexes for foreign keys, and none were defined by
-- hand, so every one of these lookups was a full table scan.
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS "likes_sender_id_idx" ON "public"."likes" ("sender_id");
CREATE INDEX IF NOT EXISTS "likes_receiver_id_idx" ON "public"."likes" ("receiver_id");
CREATE INDEX IF NOT EXISTS "likes_pair_idx" ON "public"."likes" ("sender_id", "receiver_id");

CREATE INDEX IF NOT EXISTS "messages_room_created_idx" ON "public"."messages" ("room_id", "created_at" DESC);
CREATE INDEX IF NOT EXISTS "messages_unread_idx" ON "public"."messages" ("room_id", "sender_id") WHERE ("is_read" = false);

CREATE INDEX IF NOT EXISTS "room_participants_profile_id_idx" ON "public"."room_participants" ("profile_id");

CREATE INDEX IF NOT EXISTS "rooms_event_id_idx" ON "public"."rooms" ("event_id");
CREATE INDEX IF NOT EXISTS "rooms_last_message_time_idx" ON "public"."rooms" ("last_message_time" DESC);

CREATE INDEX IF NOT EXISTS "event_likes_user_id_idx" ON "public"."event_likes" ("user_id");
CREATE INDEX IF NOT EXISTS "event_likes_event_id_idx" ON "public"."event_likes" ("event_id");

CREATE INDEX IF NOT EXISTS "event_participants_event_status_idx" ON "public"."event_participants" ("event_id", "status");
CREATE INDEX IF NOT EXISTS "event_participants_user_status_idx" ON "public"."event_participants" ("user_id", "status");

CREATE INDEX IF NOT EXISTS "events_creator_id_idx" ON "public"."events" ("creator_id");
CREATE INDEX IF NOT EXISTS "events_event_date_idx" ON "public"."events" ("event_date");

CREATE INDEX IF NOT EXISTS "profiles_phone_idx" ON "public"."profiles" ("phone");
