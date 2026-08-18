-- ============================================================================
-- Keep geo in sync with location_point, whoever writes it.
--
-- The profile editor updates location_point directly, but ranking reads geo -
-- so a location saved from the profile screen was invisible to the feed. That
-- is fixed on the client too, but a second place that writes the old column
-- would silently reintroduce the same bug, and it is the kind of bug nobody
-- notices: no error, the person simply never appears to anyone.
--
-- The trigger makes the two columns impossible to desync.
-- ============================================================================

CREATE OR REPLACE FUNCTION "public"."sync_geo_from_point"()
RETURNS "trigger"
LANGUAGE "plpgsql"
SET "search_path" = "public", "extensions", "pg_temp"
AS $$
BEGIN
  IF NEW.location_point IS NULL THEN
    NEW.geo := NULL;
  ELSE
    -- location_point is stored as point(lat, long); geography wants long first.
    NEW.geo := extensions.st_setsrid(
                 extensions.st_makepoint(NEW.location_point[1], NEW.location_point[0]),
                 4326
               )::extensions.geography;
  END IF;
  RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."sync_geo_from_point"() OWNER TO "postgres";

DROP TRIGGER IF EXISTS "profiles_sync_geo" ON "public"."profiles";
CREATE TRIGGER "profiles_sync_geo"
  BEFORE INSERT OR UPDATE OF "location_point" ON "public"."profiles"
  FOR EACH ROW EXECUTE FUNCTION "public"."sync_geo_from_point"();

DROP TRIGGER IF EXISTS "events_sync_geo" ON "public"."events";
CREATE TRIGGER "events_sync_geo"
  BEFORE INSERT OR UPDATE OF "location_point" ON "public"."events"
  FOR EACH ROW EXECUTE FUNCTION "public"."sync_geo_from_point"();
