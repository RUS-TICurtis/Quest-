-- ═══════════════════════════════════════════════════════════════════════════════
-- Migration: Creator Clips Management Improvements
-- Adds 'disabled' status, broadens creator update/delete RLS policies,
-- and ensures public feeds never surface disabled videos.
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── 1. Extend status CHECK constraint to include 'disabled' ──────────────────
ALTER TABLE public.creator_videos DROP CONSTRAINT IF EXISTS creator_videos_status_check;
ALTER TABLE public.creator_videos ADD CONSTRAINT creator_videos_status_check
  CHECK (status IN ('pending','approved','rejected','removed','processing','ready','disabled'));

-- ── 2. Expand creator RLS: allow update/delete on any owned video ─────────────
--    Old policies only allowed changes to 'pending' and 'rejected' clips,
--    which prevented creators from managing their approved or disabled clips.
DROP POLICY IF EXISTS "Creators update own pending" ON public.creator_videos;
DROP POLICY IF EXISTS "Creators delete own pending" ON public.creator_videos;

CREATE POLICY "Creators update own videos" ON public.creator_videos FOR UPDATE
  USING  (auth.uid() = creator_id)
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators delete own videos" ON public.creator_videos FOR DELETE
  USING (auth.uid() = creator_id);

-- ── 3. Rebuild get_edge_feed — exclude 'disabled' from the public feed ────────
--    Incorporates all prior fixes (self-watched demotion exclusion, COALESCE
--    null-safe bans, block compliance) plus the new 'disabled' filter.
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
    -- Watched videos are pushed to the end, EXCEPT for the creator's own uploads
    (CASE WHEN EXISTS (
      SELECT 1 FROM public.user_video_views uv
      WHERE uv.video_id = v.id AND uv.user_id = p_user_id
    ) AND v.creator_id != p_user_id THEN 1 ELSE 0 END) ASC,
    -- Prioritize modern HLS-ready Mux streams over legacy storage URLs
    (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 1 END) ASC,
    -- Engagement ranking with seed randomisation, log-decay freshness, and genre boost
    (
      COALESCE(v.engagement_score, 0.0) *
      (0.8 + 0.4 * (abs(hashtext(v.id::text || p_seed))::numeric / 2147483647.0)) *
      COALESCE(1.5 / (1.0 + LN(1.0 + EXTRACT(EPOCH FROM (now() - v.created_at))/86400.0)), 1.0) *
      CASE WHEN (
        v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND
        v.tags[1]::text = ANY(p_recent_genres)
      ) THEN 1.4 ELSE 1.0 END
    ) DESC,
    v.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
