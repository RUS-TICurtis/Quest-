-- ============================================================================
-- Fix: get_edge_feed RPC — broaden status filter to include Mux-ready videos.
--
-- Root cause: creator_videos.status defaults to 'pending'. The Mux webhook
-- only sets mux_status = 'ready'; it never auto-sets status = 'approved'.
-- This means the old RPC (WHERE status = 'approved') always returned 0 rows
-- unless an admin had manually approved each video through the moderation UI.
--
-- Fix: Accept a video if EITHER:
--   a) It has been explicitly approved by a moderator (status = 'approved'), OR
--   b) It has successfully completed Mux encoding (mux_status = 'ready')
--      and has NOT been explicitly removed/rejected.
--
-- This unblocks the feed immediately while still filtering out removed,
-- rejected, and genuinely broken videos.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_edge_feed(
  p_user_id      UUID,
  p_limit        INT,
  p_cursor_score NUMERIC
)
RETURNS TABLE (
  id                UUID,
  creator_id        UUID,
  title             TEXT,
  description       TEXT,
  video_url         TEXT,
  thumbnail_url     TEXT,
  duration_seconds  INT,
  duration_ms       INT,
  view_count        INT,
  like_count        INT,
  comment_count     INT,
  share_count       INT,
  status            TEXT,
  category          TEXT,
  avg_completion_pct NUMERIC,
  engagement_score  NUMERIC,
  mux_playback_id   TEXT,
  mux_status        TEXT,
  created_at        TIMESTAMPTZ,
  updated_at        TIMESTAMPTZ,
  deleted_at        TIMESTAMPTZ,
  creator_username  TEXT,
  creator_avatar_url TEXT
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
    -- duration_ms is a derived value: duration_seconds * 1000
    COALESCE(v.duration_seconds, 0) * 1000 AS duration_ms,
    v.view_count,
    v.like_count,
    v.comment_count,
    v.share_count,
    v.status,
    -- category maps to the first tag for now; replace with a real column when available
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
    p.username  AS creator_username,
    p.avatar_url AS creator_avatar_url
  FROM public.creator_videos v
  LEFT JOIN public.profiles p ON p.id = v.creator_id
  WHERE
    -- Soft-delete guard
    v.deleted_at IS NULL
    -- ── STATUS FILTER (broadened) ───────────────────────────────────────────
    -- Accept explicitly approved videos OR Mux-ready videos not yet moderated.
    -- Exclude: pending without a playable HLS stream, rejected, removed.
    AND (
      v.status = 'approved'
      OR (v.mux_status = 'ready' AND v.status NOT IN ('rejected', 'removed'))
    )
    -- Suppress videos under temporary suppression window (e.g. report threshold hit)
    AND (v.suppress_until IS NULL OR v.suppress_until < now())
    -- ── DEDUP: exclude videos seen in the last 7 days ──────────────────────
    AND NOT EXISTS (
      SELECT 1
      FROM public.user_video_views uv
      WHERE uv.video_id = v.id
        AND uv.user_id  = p_user_id
        AND uv.created_at > now() - interval '7 days'
    )
    -- ── CURSOR (keyset pagination by engagement_score) ─────────────────────
    AND (p_cursor_score IS NULL OR v.engagement_score < p_cursor_score)
  ORDER BY v.engagement_score DESC, v.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users (edge function runs as service role,
-- but keeping this explicit is good practice).
GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, NUMERIC) TO service_role;
