-- Migration: Add secure Mux status polling RPC
CREATE OR REPLACE FUNCTION public.get_mux_status(p_video_ids uuid[])
RETURNS TABLE (
  id uuid,
  mux_status text,
  mux_playback_id text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, mux_status, mux_playback_id
  FROM public.creator_videos
  WHERE id = ANY(p_video_ids)
    AND deleted_at IS NULL;
$$;
