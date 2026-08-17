-- ============================================================================
-- Real geography.
--
-- Two problems with what was here.
--
-- 1. Distances were wrong. The earthdistance `<@>` operator takes
--    point(longitude, latitude), but coordinates were stored and passed as
--    point(latitude, longitude). Lviv to Kyiv came out as 724.8 km against a
--    true 467.6 km - and the error is not a constant factor, it changes with
--    position, so the ordering itself was wrong, not just the labels.
--
-- 2. There was no spatial index and no way to express "within N km", because
--    a `point` column cannot have one. Every proximity query was a full scan
--    with trigonometry per row.
--
-- Coordinates move to geography(Point, 4326), which stores longitude first,
-- supports a GIST index, and makes ST_DWithin a real radius filter rather than
-- arithmetic applied after the fact. location_point is kept in sync so nothing
-- that still reads it breaks.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA "extensions";


ALTER TABLE "public"."profiles" ADD COLUMN IF NOT EXISTS "geo" extensions.geography(Point, 4326);
ALTER TABLE "public"."events"   ADD COLUMN IF NOT EXISTS "geo" extensions.geography(Point, 4326);

-- Existing values are point(lat, long), so longitude is index 1.
UPDATE "public"."profiles"
SET "geo" = extensions.st_setsrid(
              extensions.st_makepoint("location_point"[1], "location_point"[0]), 4326
            )::extensions.geography
WHERE "location_point" IS NOT NULL AND "geo" IS NULL;

UPDATE "public"."events"
SET "geo" = extensions.st_setsrid(
              extensions.st_makepoint("location_point"[1], "location_point"[0]), 4326
            )::extensions.geography
WHERE "location_point" IS NOT NULL AND "geo" IS NULL;

CREATE INDEX IF NOT EXISTS "profiles_geo_idx" ON "public"."profiles" USING GIST ("geo");
CREATE INDEX IF NOT EXISTS "events_geo_idx"   ON "public"."events"   USING GIST ("geo");

-- geo is as sensitive as location_point was, and for the same reason.
REVOKE SELECT ("geo") ON "public"."profiles" FROM "authenticated";
REVOKE SELECT ("geo") ON "public"."profiles" FROM "anon";


-- ----------------------------------------------------------------------------
-- Activity. "Nearby" is worthless if the person stopped opening the app in
-- March, so recency needs to be a first-class signal rather than inferred
-- from updated_at, which changes for unrelated reasons.
-- ----------------------------------------------------------------------------

ALTER TABLE "public"."profiles"
  ADD COLUMN IF NOT EXISTS "last_active_at" timestamp with time zone;

UPDATE "public"."profiles"
SET "last_active_at" = COALESCE("updated_at", "now"())
WHERE "last_active_at" IS NULL;

CREATE INDEX IF NOT EXISTS "profiles_last_active_idx"
  ON "public"."profiles" ("last_active_at" DESC);

GRANT SELECT ("last_active_at") ON "public"."profiles" TO "authenticated";


-- ----------------------------------------------------------------------------
-- Interest rarity.
--
-- A shared "Спорт" says almost nothing; a shared "Скелелазіння" says a lot.
-- Counting overlapping tags treats them identically, which is the main reason
-- the current matching feels arbitrary. Weighting each interest by how rare it
-- is fixes that without any model.
--
-- Materialised because it is read on every feed query and changes slowly.
-- ----------------------------------------------------------------------------

DROP MATERIALIZED VIEW IF EXISTS "public"."interest_weights";
CREATE MATERIALIZED VIEW "public"."interest_weights" AS
WITH "total" AS (SELECT GREATEST(count(*), 1)::numeric AS "n" FROM "public"."profiles")
SELECT
  "h" AS "interest",
  ln(1 + (SELECT "n" FROM "total") / GREATEST(count(*), 1)::numeric) AS "weight"
FROM "public"."profiles" "p", unnest("p"."hobbies") AS "h"
GROUP BY "h";

CREATE UNIQUE INDEX "interest_weights_pkey" ON "public"."interest_weights" ("interest");

CREATE OR REPLACE FUNCTION "public"."refresh_interest_weights"()
RETURNS "void"
LANGUAGE "sql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.interest_weights;
$$;

ALTER FUNCTION "public"."refresh_interest_weights"() OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."refresh_interest_weights"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."refresh_interest_weights"() TO "service_role";


-- ----------------------------------------------------------------------------
-- Weighted overlap between two interest sets, normalised to 0..1.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."interest_affinity"("a" "text"[], "b" "text"[])
RETURNS double precision
LANGUAGE "sql"
STABLE
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT CASE
    WHEN a IS NULL OR b IS NULL OR array_length(a,1) IS NULL OR array_length(b,1) IS NULL
      THEN 0.0
    ELSE COALESCE(
      (SELECT sum(w.weight) FROM public.interest_weights w WHERE w.interest = ANY(a) AND w.interest = ANY(b))
      /
      NULLIF((SELECT sum(w.weight) FROM public.interest_weights w
              WHERE w.interest = ANY(a) OR w.interest = ANY(b)), 0),
      0.0)::double precision
  END;
$$;

ALTER FUNCTION "public"."interest_affinity"("text"[], "text"[]) OWNER TO "postgres";
GRANT EXECUTE ON FUNCTION "public"."interest_affinity"("text"[], "text"[]) TO "authenticated";


-- ----------------------------------------------------------------------------
-- Writing your own position. Also marks you active, since the app calls this
-- on open - which is exactly when "active" means something.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."update_my_location"(
    "p_lat" double precision,
    "p_long" double precision
)
RETURNS "void"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "extensions", "pg_temp"
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF p_lat IS NULL OR p_long IS NULL
     OR p_lat NOT BETWEEN -90 AND 90 OR p_long NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'coordinates out of range' USING ERRCODE = '22023';
  END IF;

  UPDATE profiles SET
    geo            = ST_SetSRID(ST_MakePoint(p_long, p_lat), 4326)::geography,
    location_point = point(p_lat, p_long),   -- сумісність зі старим кодом
    last_active_at = now()
  WHERE id = v_uid;
END;
$$;

ALTER FUNCTION "public"."update_my_location"(double precision, double precision) OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."update_my_location"(double precision, double precision) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."update_my_location"(double precision, double precision) TO "authenticated";


CREATE OR REPLACE FUNCTION "public"."touch_last_active"()
RETURNS "void"
LANGUAGE "sql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  UPDATE public.profiles SET last_active_at = now() WHERE id = auth.uid();
$$;

ALTER FUNCTION "public"."touch_last_active"() OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."touch_last_active"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."touch_last_active"() TO "authenticated";
