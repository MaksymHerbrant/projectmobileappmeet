-- ============================================================================
-- Creating an event failed with 42501 on `rooms`.
--
-- PostgREST turns .select() after an insert into INSERT ... RETURNING, and
-- Postgres applies the SELECT policy to the returned row. rooms_select_members
-- requires the caller to be a participant - and a room that was created one
-- statement ago has no participants yet, so the row is invisible and the whole
-- statement is rejected. The policy is correct; inserting a room from the
-- client and reading it back in the same breath is what cannot work.
--
-- Folding event and chat creation into one SECURITY DEFINER function fixes
-- that and closes a second hole at the same time: these were two independent
-- client calls, so a failure between them left an event permanently without
-- its group chat.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."create_event_with_chat"(
    "p_title" "text",
    "p_description" "text",
    "p_location" "text",
    "p_event_date" timestamp with time zone,
    "p_photos" "text"[],
    "p_tags" "text"[],
    "p_participants_count" integer,
    "p_is_private" boolean,
    "p_private_location" "text",
    "p_meeting_point" "text",
    "p_additional_info" "text",
    "p_embedding" "text"
)
RETURNS "uuid"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
DECLARE
  v_uid      uuid := auth.uid();
  v_event_id uuid;
  v_room_id  uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF coalesce(trim(p_title), '') = '' THEN
    RAISE EXCEPTION 'title is required' USING ERRCODE = '22023';
  END IF;

  PERFORM public.check_rate_limit('create_event', 20, interval '1 day');

  INSERT INTO events (
    creator_id, title, description, location, event_date, photos, tags,
    participants_count, is_private, private_location, meeting_point,
    additional_info, embedding
  )
  VALUES (
    v_uid, p_title, p_description, p_location, p_event_date, p_photos, p_tags,
    p_participants_count, p_is_private, p_private_location, p_meeting_point,
    p_additional_info, p_embedding::vector
  )
  RETURNING id INTO v_event_id;

  INSERT INTO rooms (is_group, type, name, avatar_url, event_id, last_message, last_message_time)
  VALUES (
    true, 'group', p_title,
    CASE WHEN array_length(p_photos, 1) > 0 THEN p_photos[1] ELSE NULL END,
    v_event_id, 'Груповий чат створено 🥳', now()
  )
  RETURNING id INTO v_room_id;

  INSERT INTO room_participants (room_id, profile_id) VALUES (v_room_id, v_uid);

  RETURN v_event_id;
END;
$$;

ALTER FUNCTION "public"."create_event_with_chat"("text", "text", "text", timestamp with time zone, "text"[], "text"[], integer, boolean, "text", "text", "text", "text") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."create_event_with_chat"("text", "text", "text", timestamp with time zone, "text"[], "text"[], integer, boolean, "text", "text", "text", "text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."create_event_with_chat"("text", "text", "text", timestamp with time zone, "text"[], "text"[], integer, boolean, "text", "text", "text", "text") TO "authenticated";


-- ----------------------------------------------------------------------------
-- Same shape of problem for one-to-one chats. record_swipe() already creates
-- them server-side, but leaving a working entry point here means the client
-- never has to insert into rooms directly.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."get_or_create_private_chat"("p_other" "uuid")
RETURNS "uuid"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_room_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF v_uid = p_other THEN
    RAISE EXCEPTION 'cannot open a chat with yourself' USING ERRCODE = '22023';
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(
      LEAST(v_uid, p_other)::text || '/' || GREATEST(v_uid, p_other)::text, 0
    )
  );

  SELECT r.id INTO v_room_id
  FROM rooms r
  JOIN room_participants a ON a.room_id = r.id AND a.profile_id = v_uid
  JOIN room_participants b ON b.room_id = r.id AND b.profile_id = p_other
  WHERE r.type = 'private'
  LIMIT 1;

  IF v_room_id IS NOT NULL THEN
    RETURN v_room_id;
  END IF;

  INSERT INTO rooms (type, last_message, last_message_time)
  VALUES ('private', 'Новий матч! Привітайся 👋', now())
  RETURNING id INTO v_room_id;

  INSERT INTO room_participants (room_id, profile_id)
  VALUES (v_room_id, v_uid), (v_room_id, p_other);

  RETURN v_room_id;
END;
$$;

ALTER FUNCTION "public"."get_or_create_private_chat"("uuid") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_or_create_private_chat"("uuid") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_or_create_private_chat"("uuid") TO "authenticated";
