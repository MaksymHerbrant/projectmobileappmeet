-- ============================================================================
-- Push notifications in the recipient's language.
--
-- Push texts were composed on the sender's device and hardcoded in Ukrainian.
-- They are read by the *recipient*, so a Polish user got Ukrainian
-- notifications - and would keep getting them no matter how well the app
-- itself was translated, because the sender's phone has no idea what language
-- the other person uses.
--
-- The language therefore has to be stored with the profile and the text picked
-- server-side, in send-push, where the recipient is known.
-- ============================================================================

ALTER TABLE "public"."profiles"
  ADD COLUMN IF NOT EXISTS "locale" "text" NOT NULL DEFAULT 'uk';

ALTER TABLE "public"."profiles"
  ADD CONSTRAINT "profiles_locale_check"
  CHECK ("locale" IN ('uk', 'en', 'es', 'pl', 'pt'));

GRANT SELECT ("locale") ON "public"."profiles" TO "authenticated";

-- Оновлює мову поточного користувача. Викликається при зміні мови в
-- налаштуваннях і при вході.
CREATE OR REPLACE FUNCTION "public"."set_my_locale"("p_locale" "text")
RETURNS "void"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "pg_temp"
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;
  IF p_locale NOT IN ('uk','en','es','pl','pt') THEN
    RAISE EXCEPTION 'unsupported locale %', p_locale USING ERRCODE = '22023';
  END IF;

  UPDATE profiles SET locale = p_locale WHERE id = auth.uid();
END;
$$;

ALTER FUNCTION "public"."set_my_locale"("text") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."set_my_locale"("text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."set_my_locale"("text") TO "authenticated";
