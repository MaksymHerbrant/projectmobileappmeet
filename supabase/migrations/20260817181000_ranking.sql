-- ============================================================================
-- Ranking that uses the signals the product actually has.
--
-- The previous feed scored on two things: cosine distance between two one-hot
-- interest vectors, and a proximity term computed from swapped coordinates.
-- Weighted 0.7 / 0.3, that put someone 467 km away above someone 7 km away in
-- an app whose entire premise is "friends nearby".
--
-- What goes in now, and why:
--
--   affinity     weighted by how rare each shared interest is, so a shared
--                "Скелелазіння" counts for more than a shared "Спорт"
--   proximity    real metres, decaying over the radius the user chose rather
--                than a fixed constant
--   recency      someone who has not opened the app in a month is a worse
--                match than someone who was here today, regardless of taste
--   reciprocity  people who already liked you are the highest-value cards in
--                the deck and were previously ranked no differently
--   popularity   a mild dampener so the same few profiles do not absorb every
--                swipe in a small city
--
-- Weights are parameters, not constants in the body, so they can be tuned
-- against real behaviour without a migration.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."get_feed"(
    "p_radius_km" integer DEFAULT 50,
    "p_limit" integer DEFAULT 20,
    "p_offset" integer DEFAULT 0,
    "p_w_affinity" double precision DEFAULT 0.35,
    "p_w_proximity" double precision DEFAULT 0.35,
    "p_w_recency" double precision DEFAULT 0.15,
    "p_w_reciprocity" double precision DEFAULT 0.15
)
RETURNS TABLE(
    "id" "uuid",
    "name" "text",
    "age" integer,
    "description" "text",
    "photos" "text"[],
    "location" "text",
    "hobbies" "text"[],
    "dist_km" double precision,
    "affinity" double precision,
    "likes_me" boolean,
    "score" double precision
)
LANGUAGE "plpgsql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "extensions", "pg_temp"
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_geo     geography;
  v_hobbies text[];
  v_radius  double precision := GREATEST(COALESCE(p_radius_km, 50), 1) * 1000.0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT p.geo, p.hobbies INTO v_geo, v_hobbies
  FROM profiles p WHERE p.id = v_uid;

  RETURN QUERY
  WITH "candidates" AS (
    SELECT
      p.id, p.full_name, p.age, p.birth_date, p.bio, p.photos, p.location,
      p.hobbies, p.geo, p.last_active_at,
      -- ST_DWithin is the part that uses the GIST index; ST_Distance after it
      -- only runs on rows that already passed.
      CASE WHEN v_geo IS NULL OR p.geo IS NULL
           THEN NULL
           ELSE ST_Distance(p.geo, v_geo) END AS dist_m
    FROM profiles p
    WHERE p.id <> v_uid
      -- Anyone already swiped on is out of the deck.
      AND NOT EXISTS (
        SELECT 1 FROM likes l
        WHERE l.sender_id = v_uid AND l.receiver_id = p.id
      )
      -- With no position of our own we cannot filter by radius, so we do not
      -- pretend to: the feed falls back to interests and activity.
      AND (
        v_geo IS NULL
        OR (p.geo IS NOT NULL AND ST_DWithin(p.geo, v_geo, v_radius))
      )
  ),
  "scored" AS (
    SELECT
      c.*,
      public.interest_affinity(v_hobbies, c.hobbies) AS aff,
      -- Half the chosen radius is the half-life: at the edge of the circle the
      -- proximity term is small but not zero.
      CASE WHEN c.dist_m IS NULL THEN 0.3
           ELSE exp(-(c.dist_m / GREATEST(v_radius / 2.0, 1.0))) END AS prox,
      -- Full credit for today, ~0.5 at a week, near zero past a month.
      CASE WHEN c.last_active_at IS NULL THEN 0.2
           ELSE exp(-(EXTRACT(EPOCH FROM (now() - c.last_active_at)) / 604800.0))
      END AS rec,
      EXISTS (
        SELECT 1 FROM likes l
        WHERE l.sender_id = c.id AND l.receiver_id = v_uid AND l.is_like = true
      ) AS likes_me,
      (SELECT count(*) FROM likes l WHERE l.receiver_id = c.id AND l.is_like = true) AS inbound
    FROM "candidates" c
  )
  SELECT
    s.id,
    s.full_name,
    COALESCE(
      s.age,
      CASE WHEN s.birth_date IS NULL THEN NULL
           ELSE EXTRACT(YEAR FROM age(s.birth_date))::integer END
    ) AS age,
    s.bio,
    s.photos,
    s.location,
    s.hobbies,
    CASE WHEN s.dist_m IS NULL THEN NULL ELSE round((s.dist_m / 1000.0)::numeric, 1)::double precision END,
    round(s.aff::numeric, 3)::double precision,
    s.likes_me,
    round((
        p_w_affinity    * s.aff
      + p_w_proximity   * s.prox
      + p_w_recency     * s.rec
      + p_w_reciprocity * (CASE WHEN s.likes_me THEN 1.0 ELSE 0.0 END)
      -- Dampener, not a filter: popular profiles still surface, just not to
      -- the exclusion of everyone else.
      - 0.05 * ln(1 + s.inbound)
    )::numeric, 4)::double precision AS score
  FROM "scored" s
  ORDER BY score DESC, s.last_active_at DESC NULLS LAST
  LIMIT GREATEST(COALESCE(p_limit, 20), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

ALTER FUNCTION "public"."get_feed"(integer, integer, integer, double precision, double precision, double precision, double precision) OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_feed"(integer, integer, integer, double precision, double precision, double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_feed"(integer, integer, integer, double precision, double precision, double precision, double precision) TO "authenticated";


-- ----------------------------------------------------------------------------
-- Events. Same shape, with two signals specific to them: an event that starts
-- tomorrow beats one in three weeks, and one that is nearly full beats one
-- nobody joined.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."get_event_feed"(
    "p_radius_km" integer DEFAULT 50,
    "p_limit" integer DEFAULT 20,
    "p_offset" integer DEFAULT 0
)
RETURNS TABLE(
    "id" "uuid",
    "creator_id" "uuid",
    "title" "text",
    "description" "text",
    "location" "text",
    "event_date" timestamp with time zone,
    "photos" "text"[],
    "tags" "text"[],
    "participants_count" integer,
    "is_private" boolean,
    "dist_km" double precision,
    "affinity" double precision,
    "score" double precision
)
LANGUAGE "plpgsql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "extensions", "pg_temp"
AS $$
DECLARE
  v_uid     uuid := auth.uid();
  v_geo     geography;
  v_hobbies text[];
  v_radius  double precision := GREATEST(COALESCE(p_radius_km, 50), 1) * 1000.0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT p.geo, p.hobbies INTO v_geo, v_hobbies
  FROM profiles p WHERE p.id = v_uid;

  RETURN QUERY
  WITH "candidates" AS (
    SELECT
      e.*,
      CASE WHEN v_geo IS NULL OR e.geo IS NULL
           THEN NULL ELSE ST_Distance(e.geo, v_geo) END AS dist_m
    FROM events e
    WHERE e.creator_id <> v_uid
      AND (e.event_date IS NULL OR e.event_date > now())
      AND NOT EXISTS (
        SELECT 1 FROM event_likes el
        WHERE el.user_id = v_uid AND el.event_id = e.id
      )
      AND (
        v_geo IS NULL
        OR e.geo IS NULL
        OR ST_DWithin(e.geo, v_geo, v_radius)
      )
  ),
  "scored" AS (
    SELECT
      c.*,
      public.interest_affinity(v_hobbies, c.tags) AS aff,
      CASE WHEN c.dist_m IS NULL THEN 0.3
           ELSE exp(-(c.dist_m / GREATEST(v_radius / 2.0, 1.0))) END AS prox,
      -- Peaks for events within a couple of days and tails off over a month.
      CASE WHEN c.event_date IS NULL THEN 0.3
           ELSE exp(-(GREATEST(EXTRACT(EPOCH FROM (c.event_date - now())), 0) / 1209600.0))
      END AS soon,
      (SELECT count(*) FROM event_participants ep
        WHERE ep.event_id = c.id AND ep.status = 'accepted') AS joined
    FROM "candidates" c
  )
  SELECT
    s.id, s.creator_id, s.title, s.description, s.location, s.event_date,
    s.photos, s.tags, s.participants_count, s.is_private,
    CASE WHEN s.dist_m IS NULL THEN NULL ELSE round((s.dist_m / 1000.0)::numeric, 1)::double precision END,
    round(s.aff::numeric, 3)::double precision,
    round((
        0.35 * s.aff
      + 0.35 * s.prox
      + 0.20 * s.soon
      + 0.10 * LEAST(s.joined::double precision / 5.0, 1.0)
    )::numeric, 4)::double precision AS score
  FROM "scored" s
  ORDER BY score DESC, s.event_date ASC NULLS LAST
  LIMIT GREATEST(COALESCE(p_limit, 20), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$;

ALTER FUNCTION "public"."get_event_feed"(integer, integer, integer) OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_event_feed"(integer, integer, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_event_feed"(integer, integer, integer) TO "authenticated";


-- Superseded: both ranked on swapped coordinates and untweighted tag overlap.
DROP FUNCTION IF EXISTS "public"."get_smart_recommendations"("extensions"."vector", double precision, double precision, double precision, integer, "uuid"[]);
DROP FUNCTION IF EXISTS "public"."get_smart_event_recommendations"("extensions"."vector", double precision, double precision, double precision, integer, "uuid"[]);
