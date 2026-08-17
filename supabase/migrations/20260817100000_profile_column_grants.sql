-- ============================================================================
-- Actually enforce the column restrictions from 20260817090000.
--
-- That migration issued REVOKE SELECT (phone, email, fcm_token), which silently
-- did nothing: Postgres treats a table-level GRANT SELECT as covering every
-- column, and a column-level REVOKE cannot subtract from it. Verified against
-- the live database - `set role authenticated; select phone from profiles`
-- still returned rows.
--
-- The working form is to drop the table-level grant and re-grant column by
-- column, which is what this does.
--
-- Two columns beyond the obvious PII are withheld as well:
--   embedding      - the interest vector, of no use to another client
--   location_point - exact coordinates. In a product built on "who is near me",
--                    letting any account read everyone's precise position is a
--                    stalking vector, not a privacy footnote. Proximity is
--                    computed server-side in get_smart_recommendations; the
--                    caller's own values come back from get_my_match_context().
-- ============================================================================

REVOKE SELECT ON "public"."profiles" FROM "authenticated";
REVOKE SELECT ON "public"."profiles" FROM "anon";

GRANT SELECT (
  "id",
  "updated_at",
  "full_name",
  "birth_date",
  "avatar_url",
  "age",
  "location",
  "bio",
  "hobbies",
  "photos"
) ON "public"."profiles" TO "authenticated";

-- anon needs nothing: RLS already blocks it, and the signup check goes through
-- phone_is_registered(), which is SECURITY DEFINER.


-- ----------------------------------------------------------------------------
-- What the caller needs about themselves to run a recommendation query.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."get_my_match_context"()
RETURNS "jsonb"
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT "jsonb_build_object"(
    'embedding', "p"."embedding"::"text",
    'lat',  CASE WHEN "p"."location_point" IS NULL THEN NULL ELSE "p"."location_point"[0] END,
    'long', CASE WHEN "p"."location_point" IS NULL THEN NULL ELSE "p"."location_point"[1] END
  )
  FROM "public"."profiles" "p"
  WHERE "p"."id" = "auth"."uid"();
$$;

ALTER FUNCTION "public"."get_my_match_context"() OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_my_match_context"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_my_match_context"() TO "authenticated";
