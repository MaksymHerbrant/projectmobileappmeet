-- ============================================================================
-- Перехід реєстрації з телефону на пошту: дзеркало phone_is_registered.
--
-- Перевіряє auth.users, а не profiles: рядок у profiles створюється тригером
-- одночасно, але email у ньому може бути порожнім залежно від шляху входу,
-- а тут потрібна відповідь «чи існує акаунт», без винятків.
-- Відповідь — рівно так/ні; перебирати адреси заважає ліміт частоти на анонах.
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
  );
$$;

ALTER FUNCTION "public"."email_is_registered"("text") OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."email_is_registered"("text") FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."email_is_registered"("text") TO "anon";
GRANT EXECUTE ON FUNCTION "public"."email_is_registered"("text") TO "authenticated";
