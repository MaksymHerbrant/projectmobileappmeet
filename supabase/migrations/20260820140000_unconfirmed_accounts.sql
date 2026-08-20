-- ============================================================================
-- Реєстрація з поштою: покинута на кроці коду спроба не має лишати слідів.
--
-- 1) email_is_registered рахує лише підтверджені акаунти. Непідтверджений
--    запис створюється самим фактом відправлення коду, і без цієї поправки
--    адреса блокувалась би назавжди після першої ж покинутої спроби.
--
-- 2) get_feed не показує профілі без імені: рядок у profiles створюється
--    тригером до завершення анкети, і такий «привид» не має потрапляти в
--    колоду. Раніше він міг — фільтра не було.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."email_is_registered"("p_email" "text")
RETURNS boolean
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "auth", "pg_temp"
AS $$
  SELECT EXISTS (
    SELECT 1 FROM "auth"."users"
    WHERE lower("email") = lower(trim("p_email"))
      AND "email_confirmed_at" IS NOT NULL
  );
$$;


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
      -- Профіль без імені — незавершена реєстрація, у колоду не потрапляє.
      AND COALESCE(p.full_name, '') <> ''
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

