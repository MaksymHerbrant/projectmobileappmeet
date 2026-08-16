-- ============================================================================
-- One query for the chat list.
--
-- getMyChatsStream() subscribed to every row in `rooms` and then, for each
-- room, issued four more queries (am I a participant, who else is, how many
-- unread, who wrote last). Twenty chats meant roughly eighty round trips, and
-- the whole loop re-ran whenever any room in the product changed - not just
-- the caller's. That is the single hottest path in the app.
--
-- get_my_conversations() already existed but was never called, and it is not
-- usable as-is: it takes the caller's id as a parameter, ignores group chats
-- (no is_group, no avatar_url, no sender prefix) and its LEFT JOIN emits one
-- duplicate row per extra participant, so every group chat would appear N
-- times. This replaces it.
--
-- SECURITY DEFINER is deliberate: the row set is derived from auth.uid(), so
-- scoping is enforced here rather than paid for again through RLS on every
-- joined row.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."get_my_chats"()
RETURNS TABLE (
    "room_id" "uuid",
    "type" "text",
    "name" "text",
    "photo" "text",
    "last_message" "text",
    "last_message_time" timestamp with time zone,
    "unread_count" bigint,
    "other_user_id" "uuid",
    "other_user_name" "text",
    "other_user_photo" "text"
)
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT
    "r"."id",
    CASE WHEN COALESCE("r"."is_group", false) OR "r"."type" = 'group'
         THEN 'group' ELSE 'private' END,
    CASE WHEN COALESCE("r"."is_group", false) OR "r"."type" = 'group'
         THEN COALESCE("r"."name", 'Група події')
         ELSE "other"."full_name" END,
    CASE WHEN COALESCE("r"."is_group", false) OR "r"."type" = 'group'
         THEN COALESCE("r"."avatar_url", "r"."photo")
         ELSE ("other"."photos")[1] END,
    -- У груповому чаті показуємо, хто саме написав останнє повідомлення.
    CASE WHEN (COALESCE("r"."is_group", false) OR "r"."type" = 'group')
              AND "sender"."full_name" IS NOT NULL
         THEN "sender"."full_name" || ': ' || COALESCE("r"."last_message", '')
         ELSE "r"."last_message" END,
    "r"."last_message_time",
    COALESCE("unread"."count", 0),
    "other"."id",
    "other"."full_name",
    ("other"."photos")[1]
  FROM "public"."room_participants" "me"
  JOIN "public"."rooms" "r" ON "r"."id" = "me"."room_id"
  -- LATERAL + LIMIT 1: у приватній кімнаті співрозмовник рівно один, і саме це
  -- не дає груповим чатам розмножитись на кожного учасника.
  LEFT JOIN LATERAL (
    SELECT "p".*
    FROM "public"."room_participants" "rp"
    JOIN "public"."profiles" "p" ON "p"."id" = "rp"."profile_id"
    WHERE "rp"."room_id" = "r"."id" AND "rp"."profile_id" <> "me"."profile_id"
    LIMIT 1
  ) "other" ON NOT (COALESCE("r"."is_group", false) OR "r"."type" = 'group')
  LEFT JOIN "public"."profiles" "sender" ON "sender"."id" = "r"."last_message_sender_id"
  LEFT JOIN LATERAL (
    SELECT count(*) AS "count"
    FROM "public"."messages" "m"
    WHERE "m"."room_id" = "r"."id"
      AND "m"."is_read" = false
      AND "m"."sender_id" <> "me"."profile_id"
  ) "unread" ON true
  WHERE "me"."profile_id" = "auth"."uid"()
  ORDER BY "r"."last_message_time" DESC NULLS LAST;
$$;

ALTER FUNCTION "public"."get_my_chats"() OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_my_chats"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_my_chats"() TO "authenticated";

-- Superseded: takes the caller id as an argument and duplicates group rows.
DROP FUNCTION IF EXISTS "public"."get_my_conversations"("uuid");
