-- Rebuild get_edge_feed to sort purely by seed-based hash and remove seen-video demotions
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
    -- Robust NULL-safe ban check
    AND COALESCE(p.is_banned, false) = false
    -- Shadowbanned creators: only visible to themselves
    AND (COALESCE(p.is_shadowbanned, false) = false OR v.creator_id = p_user_id)
    -- Block compliance: exclude videos from blocked/blocking creators
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = p_user_id AND ub.blocked_id = v.creator_id)
          OR (ub.blocker_id = v.creator_id AND ub.blocked_id = p_user_id)
    )
    -- Status filter: 'disabled' is now excluded alongside 'rejected' and 'removed'
    AND (
      v.status = 'approved'
      OR (v.mux_status = 'ready' AND v.status NOT IN ('rejected', 'removed', 'disabled'))
    )
    AND (v.suppress_until IS NULL OR v.suppress_until < now())
  ORDER BY
    -- Prioritize modern HLS-ready Mux streams over legacy storage URLs
    (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 1 END) ASC,
    -- Pure seed-based randomized shuffle
    abs(hashtext(v.id::text || p_seed)) ASC,
    -- Engagement score and creation date as fallbacks
    COALESCE(v.engagement_score, 0.0) DESC,
    v.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) FROM anon;

GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]) TO postgres;
