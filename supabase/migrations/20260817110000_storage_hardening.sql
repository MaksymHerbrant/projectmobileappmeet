-- ============================================================================
-- Storage: size limits, type limits, folder scoping, and a way to delete.
--
-- Both buckets had no file_size_limit and no allowed_mime_types, so any
-- account could upload a file of any size and any type - a direct cost and
-- abuse vector, and the cheapest way to take the project's bandwidth budget
-- down overnight.
--
-- The policies were equally loose:
--   * event_photos accepted an INSERT from anyone, into any path, with no
--     ownership check at all
--   * neither bucket had a DELETE policy, so users could not remove their own
--     photos and nothing was ever cleaned up
--   * uploads were not scoped to a per-user folder, so one user could write
--     over another's object path
--
-- Read access stays public for now. Switching to private buckets with signed
-- URLs is a client-side change - every stored value is a full public URL today
-- and would have to become a path - and is handled separately.
-- ============================================================================

UPDATE "storage"."buckets"
SET "file_size_limit" = 5242880,  -- 5 MB; the client already downscales to 1080px
    "allowed_mime_types" = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
WHERE "id" IN ('avatars', 'event_photos');


-- ----------------------------------------------------------------------------
-- Policies. Every write is scoped to a folder named after the caller's uid,
-- which is the convention the client now follows for both buckets.
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "Anyone can upload an avatar." ON "storage"."objects";
DROP POLICY IF EXISTS "Anyone can update their own avatar." ON "storage"."objects";
DROP POLICY IF EXISTS "Anyone can upload an photo. fxda6e_0" ON "storage"."objects";
DROP POLICY IF EXISTS "Avatar images are publicly accessible." ON "storage"."objects";

CREATE POLICY "media_read_public" ON "storage"."objects"
  FOR SELECT
  USING ("bucket_id" IN ('avatars', 'event_photos'));

CREATE POLICY "media_insert_own_folder" ON "storage"."objects"
  FOR INSERT TO "authenticated"
  WITH CHECK (
    "bucket_id" IN ('avatars', 'event_photos')
    AND ("storage"."foldername"("name"))[1] = "auth"."uid"()::"text"
  );

CREATE POLICY "media_update_own_folder" ON "storage"."objects"
  FOR UPDATE TO "authenticated"
  USING (
    "bucket_id" IN ('avatars', 'event_photos')
    AND ("storage"."foldername"("name"))[1] = "auth"."uid"()::"text"
  )
  WITH CHECK (
    "bucket_id" IN ('avatars', 'event_photos')
    AND ("storage"."foldername"("name"))[1] = "auth"."uid"()::"text"
  );

CREATE POLICY "media_delete_own_folder" ON "storage"."objects"
  FOR DELETE TO "authenticated"
  USING (
    "bucket_id" IN ('avatars', 'event_photos')
    AND ("storage"."foldername"("name"))[1] = "auth"."uid"()::"text"
  );


-- ----------------------------------------------------------------------------
-- Deleting an account has to take its files with it, otherwise the photos of
-- someone who left stay served from a public URL indefinitely.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION "public"."delete_user"()
RETURNS "void"
LANGUAGE "plpgsql"
SECURITY DEFINER
SET "search_path" = "public", "storage", "pg_temp"
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated' USING ERRCODE = '28000';
  END IF;

  DELETE FROM storage.objects
  WHERE bucket_id IN ('avatars', 'event_photos')
    AND (storage.foldername(name))[1] = v_uid::text;

  DELETE FROM auth.users WHERE id = v_uid;
END;
$$;

ALTER FUNCTION "public"."delete_user"() OWNER TO "postgres";
REVOKE ALL ON FUNCTION "public"."delete_user"() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION "public"."delete_user"() TO "authenticated";
