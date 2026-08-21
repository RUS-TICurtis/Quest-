-- Create RPC function to securely execute the optimized feed query
-- Filter -> Limit pattern
CREATE OR REPLACE FUNCTION public.get_edge_feed(p_user_id UUID, p_limit INT, p_cursor_score NUMERIC)
RETURNS TABLE (
  id UUID,
  creator_id UUID,
  title TEXT,
  description TEXT,
  video_url TEXT,
  thumbnail_url TEXT,
  duration_seconds INT,
  duration_ms INT,
  view_count INT,
  like_count INT,
  comment_count INT,
  share_count INT,
  status TEXT,
  category TEXT,
  avg_completion_pct NUMERIC,
  engagement_score NUMERIC,
  mux_playback_id TEXT,
  mux_status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  creator_username TEXT,
  creator_avatar_url TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id, v.creator_id, v.title, v.description, v.video_url, v.thumbnail_url,
    v.duration_seconds, v.duration_ms, v.view_count, v.like_count, v.comment_count,
    v.share_count, v.status, v.category, v.avg_completion_pct, v.engagement_score,
    v.mux_playback_id, v.mux_status, v.created_at, v.updated_at, v.deleted_at,
    p.username AS creator_username, p.avatar_url AS creator_avatar_url
  FROM public.creator_videos v
  LEFT JOIN public.profiles p ON p.id = v.creator_id
  WHERE v.deleted_at IS NULL AND v.status = 'approved'
  AND NOT EXISTS (
    SELECT 1 FROM public.user_video_views uv
    WHERE uv.video_id = v.id
    AND uv.user_id = p_user_id
    AND uv.created_at > now() - interval '7 days'
  )
  AND (p_cursor_score IS NULL OR v.engagement_score < p_cursor_score)
  ORDER BY v.engagement_score DESC, v.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
