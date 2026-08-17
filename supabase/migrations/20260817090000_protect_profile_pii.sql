-- ============================================================================
-- Keep phone numbers and e-mails out of the matching feed.
--
-- profiles has to stay readable by every authenticated user - that is what the
-- feed is - but it also carries phone, email and fcm_token. Any account could
-- page through the table and walk away with the phone number of every user in
-- the product.
--
-- RLS cannot express this: it filters rows, not columns. Column-level REVOKE
-- can, with one consequence - PostgREST turns a bare .select() into `select *`,
-- which now fails. Every client read is therefore switched to an explicit
-- column list in the same change, and the one place that legitimately needs the
-- caller's own phone gets a self-scoped RPC.
-- ============================================================================

REVOKE SELECT ("phone", "email", "fcm_token") ON "public"."profiles" FROM "authenticated";
REVOKE SELECT ("phone", "email", "fcm_token") ON "public"."profiles" FROM "anon";

-- Writes stay as they were: RLS already limits UPDATE to auth.uid() = id, and
-- signup needs to write its own phone.


-- ----------------------------------------------------------------------------
-- The caller's own profile, in full.
--
-- Scoped to auth.uid(), so SECURITY DEFINER hands back the private columns
-- without opening them to anyone else.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."get_my_profile"()
RETURNS "jsonb"
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT "to_jsonb"("p") - 'embedding'
  FROM "public"."profiles" "p"
  WHERE "p"."id" = "auth"."uid"();
$$;

ALTER FUNCTION "public"."get_my_profile"() OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."get_my_profile"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."get_my_profile"() TO "authenticated";


-- ----------------------------------------------------------------------------
-- Signup checks whether a phone is already registered. That lookup cannot go
-- through the table any more, and it must not become a way to enumerate who
-- is on the product either - so it answers a boolean and nothing else.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."phone_is_registered"("p_phone" "text")
RETURNS boolean
LANGUAGE "sql"
STABLE
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
  SELECT EXISTS (SELECT 1 FROM "public"."profiles" WHERE "phone" = "p_phone");
$$;

ALTER FUNCTION "public"."phone_is_registered"("text") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."phone_is_registered"("text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."phone_is_registered"("text") TO "anon";
GRANT EXECUTE ON FUNCTION "public"."phone_is_registered"("text") TO "authenticated";
