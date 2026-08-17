-- ============================================================================
-- Rate limits on the three actions that cost money or reach other people.
--
-- Nothing throttled swipes, messages or likes. One script could exhaust the
-- SMS budget, blanket every user with push notifications, or fill the messages
-- table overnight - and every one of those is cheap to do, because all three
-- paths are reachable with nothing but a signed-up account.
--
-- Enforcement lives in the database rather than the client for the obvious
-- reason: a client-side limit is a suggestion.
-- ============================================================================

CREATE TABLE IF NOT EXISTS "public"."rate_events" (
    "id" bigserial PRIMARY KEY,
    "profile_id" "uuid" NOT NULL REFERENCES "public"."profiles"("id") ON DELETE CASCADE,
    "action" "text" NOT NULL,
    "created_at" timestamp with time zone NOT NULL DEFAULT "now"()
);

ALTER TABLE "public"."rate_events" OWNER TO "postgres";
ALTER TABLE "public"."rate_events" ENABLE ROW LEVEL SECURITY;

-- No policies at all: only SECURITY DEFINER functions touch this table.
-- Clients must not be able to read their own counters, let alone delete them.

CREATE INDEX IF NOT EXISTS "rate_events_lookup_idx"
  ON "public"."rate_events" ("profile_id", "action", "created_at" DESC);


-- ----------------------------------------------------------------------------
-- Records one occurrence and raises if the caller is over the limit.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."check_rate_limit"(
    "p_action" "text",
    "p_limit" integer,
    "p_window" interval
)
RETURNS "void"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
DECLARE
  v_uid   uuid := auth.uid();
  v_count integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT count(*) INTO v_count
  FROM rate_events
  WHERE profile_id = v_uid
    AND action = p_action
    AND created_at > now() - p_window;

  IF v_count >= p_limit THEN
    RAISE EXCEPTION 'rate limit exceeded for %', p_action
      USING ERRCODE = '53400', HINT = 'too_many_requests';
  END IF;

  INSERT INTO rate_events (profile_id, action) VALUES (v_uid, p_action);
END;
$$;

ALTER FUNCTION "public"."check_rate_limit"("text", integer, interval) OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."check_rate_limit"("text", integer, interval) FROM PUBLIC;


-- ----------------------------------------------------------------------------
-- Swipes: 300 a day is far above real use and far below scripted use.
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

  PERFORM public.check_rate_limit('swipe', 300, interval '1 day');

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
-- Messages: enforced by trigger, so it holds no matter which path inserts.
-- 60 a minute is well past human typing speed.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."enforce_message_rate_limit"()
RETURNS "trigger"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
BEGIN
  IF auth.uid() IS NOT NULL THEN
    PERFORM public.check_rate_limit('message', 60, interval '1 minute');
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."enforce_message_rate_limit"() OWNER TO "postgres";

DROP TRIGGER IF EXISTS "messages_rate_limit" ON "public"."messages";
CREATE TRIGGER "messages_rate_limit"
  BEFORE INSERT ON "public"."messages"
  FOR EACH ROW EXECUTE FUNCTION "public"."enforce_message_rate_limit"();


-- ----------------------------------------------------------------------------
-- Event join requests, same shape.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."enforce_event_request_rate_limit"()
RETURNS "trigger"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND NEW.user_id = auth.uid() THEN
    PERFORM public.check_rate_limit('event_request', 100, interval '1 day');
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."enforce_event_request_rate_limit"() OWNER TO "postgres";

DROP TRIGGER IF EXISTS "event_participants_rate_limit" ON "public"."event_participants";
CREATE TRIGGER "event_participants_rate_limit"
  BEFORE INSERT ON "public"."event_participants"
  FOR EACH ROW EXECUTE FUNCTION "public"."enforce_event_request_rate_limit"();


-- ----------------------------------------------------------------------------
-- The counters are only ever read over a short window, so old rows are dead
-- weight. Trimmed opportunistically rather than with a scheduled job.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."prune_rate_events"()
RETURNS "void"
LANGUAGE "sql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  DELETE FROM rate_events WHERE created_at < now() - interval '2 days';
$$;

ALTER FUNCTION "public"."prune_rate_events"() OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."prune_rate_events"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."prune_rate_events"() TO "service_role";
