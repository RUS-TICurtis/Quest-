-- Migration to restrict direct client access to get_edge_feed RPC
-- Only the Deno Edge Function (executing via service_role) is allowed to call this function.

REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) FROM anon;

GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) TO postgres;

-- Backfill tmdb_title for existing database videos where tmdb_id is present but tmdb_title is null.
-- For show/movie tagged uploads, the main post 'title' is used as the linked show name.
UPDATE public.creator_videos
SET tmdb_title = title
WHERE tmdb_id IS NOT NULL AND tmdb_title IS NULL;
