-- ============================================================================
-- Fix: the recommendation RPCs broke when embedding and location_point were
-- revoked from `authenticated` in 20260817100000.
--
-- Both functions read those two columns internally - the vector distance and
-- the proximity term are the whole point of them - and both were SECURITY
-- INVOKER, so they ran with the caller's privileges and started failing with
-- "permission denied for table profiles" (42501). The feed silently fell back
-- to the non-personalised path on every load.
--
-- SECURITY DEFINER is the right answer rather than re-granting the columns:
-- the functions return only fields the caller may already see, plus a distance
-- computed relative to the caller. Raw coordinates never leave the database,
-- which is exactly the property the revoke was protecting.
--
-- Bodies are unchanged apart from the security clause and a pinned search_path.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."get_smart_recommendations"(
    "query_embedding" "public"."vector",
    "user_lat" double precision,
    "user_long" double precision,
    "match_threshold" double precision,
    "match_count" integer,
    "ignored_ids" "uuid"[]
)
RETURNS TABLE(
    "id" "uuid", "name" "text", "age" integer, "description" "text",
    "photos" "text"[], "location" "text", "hobbies" "text"[],
    "similarity" double precision, "dist_km" double precision,
    "final_score" double precision
)
LANGUAGE "plpgsql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "extensions", "pg_temp"
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.full_name as name,
    p.age,
    p.bio as description,
    p.photos,
    p.location,
    p.hobbies,

    (1 - (p.embedding <=> query_embedding))::float AS similarity,

    (point(p.location_point[0], p.location_point[1]) <@> point(user_lat, user_long))::float * 1.60934 AS dist_km,

    (
      (1 - (p.embedding <=> query_embedding)) * 0.7 +
      (1.0 / (1.0 + ((point(p.location_point[0], p.location_point[1]) <@> point(user_lat, user_long)) * 1.60934 / 20.0))) * 0.3
    )::float AS final_score

  FROM public.profiles p
  WHERE
    p.id != auth.uid()
    AND NOT (p.id = ANY(ignored_ids))
    AND (1 - (p.embedding <=> query_embedding)) > match_threshold
    AND p.location_point IS NOT NULL
  ORDER BY final_score DESC
  LIMIT match_count;
END;
$$;

ALTER FUNCTION "public"."get_smart_recommendations"("public"."vector", double precision, double precision, double precision, integer, "uuid"[]) OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_smart_recommendations"("public"."vector", double precision, double precision, double precision, integer, "uuid"[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_smart_recommendations"("public"."vector", double precision, double precision, double precision, integer, "uuid"[]) TO "authenticated";


CREATE OR REPLACE FUNCTION "public"."get_smart_event_recommendations"(
    "query_embedding" "public"."vector",
    "user_lat" double precision,
    "user_long" double precision,
    "match_threshold" double precision,
    "match_count" integer,
    "ignored_ids" "uuid"[]
)
RETURNS TABLE(
    "id" "uuid", "creator_id" "uuid", "title" "text", "description" "text",
    "location" "text", "event_date" timestamp with time zone,
    "photos" "text"[], "tags" "text"[], "participants_count" integer,
    "similarity" double precision, "dist_km" double precision
)
LANGUAGE "plpgsql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "extensions", "pg_temp"
AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.creator_id,
    e.title,
    e.description,
    e.location,
    e.event_date,
    e.photos,
    e.tags,
    e.participants_count,

    (1 - (e.embedding <=> query_embedding))::float AS similarity,

    CASE
      WHEN e.location_point IS NOT NULL THEN
        (point(e.location_point[0], e.location_point[1]) <@> point(user_lat, user_long))::float * 1.60934
      ELSE 1000.0
    END AS dist_km

  FROM public.events e
  WHERE
    e.creator_id != auth.uid()
    AND NOT (e.id = ANY(ignored_ids))
    AND (1 - (e.embedding <=> query_embedding)) > match_threshold
  ORDER BY similarity DESC, dist_km ASC
  LIMIT match_count;
END;
$$;

ALTER FUNCTION "public"."get_smart_event_recommendations"("public"."vector", double precision, double precision, double precision, integer, "uuid"[]) OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_smart_event_recommendations"("public"."vector", double precision, double precision, double precision, integer, "uuid"[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_smart_event_recommendations"("public"."vector", double precision, double precision, double precision, integer, "uuid"[]) TO "authenticated";
