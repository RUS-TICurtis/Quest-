-- Migration to push already-watched videos to the end of the feed
CREATE OR REPLACE FUNCTION public.get_edge_feed(
  p_user_id        UUID,
  p_limit          INT,
  p_offset         INT,
  p_seed           TEXT,
  p_recent_genres  TEXT[] DEFAULT '{}'
)
RETURNS TABLE (
  id                 UUID,
  creator_id         UUID,
  title              TEXT,
  description        TEXT,
  video_url          TEXT,
  thumbnail_url      TEXT,
  duration_seconds   INT,
  duration_ms        INT,
  view_count         INT,
  like_count         INT,
  comment_count      INT,
  share_count        INT,
  status             TEXT,
  category           TEXT,
  avg_completion_pct NUMERIC,
  engagement_score   NUMERIC,
  mux_playback_id    TEXT,
  mux_status         TEXT,
  created_at         TIMESTAMPTZ,
  updated_at         TIMESTAMPTZ,
  deleted_at         TIMESTAMPTZ,
  creator_username   TEXT,
  creator_avatar_url TEXT,
  tmdb_id            INT,
  tmdb_title         TEXT,
  tmdb_type          TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    v.id,
    v.creator_id,
    v.title,
    v.description,
    v.video_url,
    v.thumbnail_url,
    v.duration_seconds,
    COALESCE(v.duration_seconds, 0) * 1000 AS duration_ms,
    v.view_count,
    v.like_count,
    v.comment_count,
    v.share_count,
    v.status,
    CASE WHEN v.tags IS NOT NULL AND array_length(v.tags, 1) > 0
         THEN v.tags[1]
         ELSE NULL
    END AS category,
    v.avg_completion_pct,
    v.engagement_score,
    v.mux_playback_id,
    v.mux_status,
    v.created_at,
    v.updated_at,
    v.deleted_at,
    p.username   AS creator_username,
    p.avatar_url AS creator_avatar_url,
    v.tmdb_id,
    v.tmdb_title,
    v.tmdb_type
  FROM public.creator_videos v
  LEFT JOIN public.profiles p ON p.id = v.creator_id
  WHERE
    v.deleted_at IS NULL
    -- Restrict videos from banned creators
    AND p.is_banned = false
    -- Support shadowbanning: shadowbanned creator videos only visible to themselves
    AND (p.is_shadowbanned = false OR v.creator_id = p_user_id)
    -- COMPLIANCE: Exclude videos where creator is blocked by viewer or viewer is blocked by creator
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = p_user_id AND ub.blocked_id = v.creator_id)
          OR (ub.blocker_id = v.creator_id AND ub.blocked_id = p_user_id)
    )
    AND (
      v.status = 'approved'
      OR (v.mux_status = 'ready' AND v.status NOT IN ('rejected', 'removed'))
    )
    AND (v.suppress_until IS NULL OR v.suppress_until < now())
  ORDER BY 
    -- Watched videos are pushed to the end of the feed (0 first, 1 last)
    (CASE WHEN EXISTS (
      SELECT 1 FROM public.user_video_views uv
      WHERE uv.video_id = v.id AND uv.user_id = p_user_id
    ) THEN 1 ELSE 0 END) ASC,
    -- Prioritize modern HLS-ready videos over slow legacy Storage URLs
    (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 1 END) ASC,
    -- Then rank by engagement, randomized seed hashing, log age decay, and genre boosts
    (
      COALESCE(v.engagement_score, 0.0) * 
      (0.8 + 0.4 * (abs(hashtext(v.id::text || p_seed))::numeric / 2147483647.0)) * 
      -- Freshness boost: log-decay of video age in days
      COALESCE(1.5 / (1.0 + LN(1.0 + EXTRACT(EPOCH FROM (now() - v.created_at))/86400.0)), 1.0) *
      -- AI Personalization Genre Boost (+40% boost if in user's recent genres)
      CASE WHEN (
        v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND 
        v.tags[1]::text = ANY(p_recent_genres)
      ) THEN 1.4 ELSE 1.0 END
    ) DESC,
    v.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
