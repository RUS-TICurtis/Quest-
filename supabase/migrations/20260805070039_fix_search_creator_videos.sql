-- Fix search_creator_videos to include all necessary fields for video playback

DROP FUNCTION IF EXISTS public.search_creator_videos(text, int, int);

CREATE OR REPLACE FUNCTION public.search_creator_videos(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID,
  creator_id UUID,
  creator_username TEXT,
  creator_avatar_url TEXT,
  title TEXT,
  description TEXT,
  thumbnail_url TEXT,
  video_url TEXT,
  view_count INT,
  like_count INT,
  comment_count INT,
  share_count INT,
  engagement_score NUMERIC,
  mux_playback_id TEXT,
  mux_status TEXT,
  status TEXT,
  tmdb_id INT,
  tmdb_type TEXT,
  tmdb_title TEXT,
  duration_seconds INT,
  spoiler BOOLEAN,
  tags TEXT[],
  created_at TIMESTAMPTZ,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cv.id, 
    cv.creator_id, 
    p.username AS creator_username,
    p.avatar_url AS creator_avatar_url,
    cv.title, 
    cv.description, 
    cv.thumbnail_url, 
    cv.video_url, 
    cv.view_count, 
    cv.like_count, 
    cv.comment_count,
    cv.share_count,
    cv.engagement_score,
    cv.mux_playback_id,
    cv.mux_status,
    cv.status,
    cv.tmdb_id,
    cv.tmdb_type,
    cv.tmdb_title,
    cv.duration_seconds,
    cv.spoiler,
    cv.tags,
    cv.created_at,
    ((ts_rank(cv.search_vector, websearch_to_tsquery('english', p_query)) * 0.7) +
    (LN(GREATEST(COALESCE(cv.engagement_score, 0), 1)) * 0.2) +
    (EXP(-EXTRACT(EPOCH FROM (now() - cv.created_at))/86400.0) * 0.1))::REAL AS rank
  FROM public.creator_videos cv
  LEFT JOIN public.profiles p ON p.id = cv.creator_id
  WHERE cv.search_vector @@ websearch_to_tsquery('english', p_query)
    AND cv.status = 'approved'
    AND cv.deleted_at IS NULL
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
