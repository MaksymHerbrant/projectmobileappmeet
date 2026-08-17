-- ============================================================================
-- Make a swipe one atomic operation.
--
-- recordSwipe() ran as four separate client round trips: look for an incoming
-- like, update it, insert my own, create the chat. Two people swiping right on
-- each other at the same moment both saw "no incoming like yet", so both took
-- the non-match path - or, on the other interleaving, both created a room and
-- the pair ended up with two chats and a duplicated match.
--
-- There is also no unique key on the pair, so the upserts in this flow have
-- been inserting duplicate rows rather than updating.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Deduplicate before the constraints go on. Keeps the newest row per pair,
-- preserving is_accepted if any of the duplicates had it set.
-- ----------------------------------------------------------------------------

UPDATE "public"."likes" "keep"
SET "is_accepted" = true
WHERE "is_accepted" IS DISTINCT FROM true
  AND EXISTS (
    SELECT 1 FROM "public"."likes" "dup"
    WHERE "dup"."sender_id" = "keep"."sender_id"
      AND "dup"."receiver_id" = "keep"."receiver_id"
      AND "dup"."is_accepted" = true
  );

DELETE FROM "public"."likes" "l"
WHERE "l"."ctid" NOT IN (
  SELECT DISTINCT ON ("sender_id", "receiver_id") "ctid"
  FROM "public"."likes"
  ORDER BY "sender_id", "receiver_id", "created_at" DESC NULLS LAST
);

DELETE FROM "public"."event_likes" "e"
WHERE "e"."ctid" NOT IN (
  SELECT DISTINCT ON ("user_id", "event_id") "ctid"
  FROM "public"."event_likes"
  ORDER BY "user_id", "event_id", "created_at" DESC NULLS LAST
);

ALTER TABLE "public"."likes"
  ADD CONSTRAINT "likes_sender_receiver_key" UNIQUE ("sender_id", "receiver_id");

ALTER TABLE "public"."event_likes"
  ADD CONSTRAINT "event_likes_user_event_key" UNIQUE ("user_id", "event_id");

-- likes_pair_idx from the RLS migration is now redundant: the unique
-- constraint provides the same (sender_id, receiver_id) index.
DROP INDEX IF EXISTS "public"."likes_pair_idx";


-- ----------------------------------------------------------------------------
-- One swipe, one transaction.
--
-- The advisory lock is taken on the unordered pair, so both directions of the
-- same couple serialise against each other and only one of two simultaneous
-- right-swipes can be the one that creates the room.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."record_swipe"(
    "p_receiver" "uuid",
    "p_is_like" boolean,
    "p_message" "text" DEFAULT NULL
)
RETURNS "jsonb"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
DECLARE
  v_sender  uuid := auth.uid();
  v_mutual  boolean;
  v_room_id uuid;
BEGIN
  IF v_sender IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF v_sender = p_receiver THEN
    RAISE EXCEPTION 'cannot swipe on yourself' USING ERRCODE = '22023';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(
      LEAST(v_sender, p_receiver)::text || '/' || GREATEST(v_sender, p_receiver)::text,
      0
    )
  );

  INSERT INTO likes (sender_id, receiver_id, is_like, is_accepted, message)
  VALUES (v_sender, p_receiver, p_is_like, false, p_message)
  ON CONFLICT (sender_id, receiver_id) DO UPDATE
    SET is_like = EXCLUDED.is_like,
        message = COALESCE(EXCLUDED.message, likes.message);

  IF NOT p_is_like THEN
    RETURN jsonb_build_object('matched', false);
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM likes
    WHERE sender_id = p_receiver AND receiver_id = v_sender AND is_like = true
  ) INTO v_mutual;

  IF NOT v_mutual THEN
    RETURN jsonb_build_object('matched', false);
  END IF;

  UPDATE likes SET is_accepted = true
  WHERE (sender_id = v_sender   AND receiver_id = p_receiver)
     OR (sender_id = p_receiver AND receiver_id = v_sender);

  SELECT r.id INTO v_room_id
  FROM rooms r
  JOIN room_participants a ON a.room_id = r.id AND a.profile_id = v_sender
  JOIN room_participants b ON b.room_id = r.id AND b.profile_id = p_receiver
  WHERE r.type = 'private'
  LIMIT 1;

  IF v_room_id IS NULL THEN
    INSERT INTO rooms (type, last_message, last_message_time)
    VALUES ('private', 'Новий матч! Привітайся 👋', now())
    RETURNING id INTO v_room_id;

    INSERT INTO room_participants (room_id, profile_id)
    VALUES (v_room_id, v_sender), (v_room_id, p_receiver);
  END IF;

  RETURN jsonb_build_object('matched', true, 'room_id', v_room_id);
END;
$$;

ALTER FUNCTION "public"."record_swipe"("uuid", boolean, "text") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."record_swipe"("uuid", boolean, "text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."record_swipe"("uuid", boolean, "text") TO "authenticated";


-- ----------------------------------------------------------------------------
-- Accepting an incoming request is the same operation as liking that person
-- back, so it runs through the same path instead of repeating the race.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."accept_like"("p_like_id" "uuid")
RETURNS "jsonb"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
DECLARE
  v_sender uuid;
BEGIN
  SELECT sender_id INTO v_sender
  FROM likes
  WHERE id = p_like_id AND receiver_id = auth.uid();

  IF v_sender IS NULL THEN
    RAISE EXCEPTION 'like not found' USING ERRCODE = 'no_data_found';
  END IF;

  RETURN public.record_swipe(v_sender, true, NULL);
END;
$$;

ALTER FUNCTION "public"."accept_like"("uuid") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."accept_like"("uuid") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."accept_like"("uuid") TO "authenticated";
