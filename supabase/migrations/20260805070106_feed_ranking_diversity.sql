-- ============================================================================
-- Feed Ranking Diversity & Session Seed Support
--
-- 1. Adds session_seed + expiry to feed_sessions for frozen-seed pagination.
-- 2. Rewrites compute_feed_rankings() with creator diversity penalties:
--    - Creator's top 2 videos keep full score
--    - 3rd video → 60% score
--    - 4th+ videos → 30% score
--    This bakes diversity into the materialized ranking so the feed query
--    doesn't need post-processing spacing filters.
-- ============================================================================

-- ── Step 1: Extend feed_sessions ─────────────────────────────────────────────

ALTER TABLE public.feed_sessions
  ADD COLUMN IF NOT EXISTS session_seed TEXT,
  ADD COLUMN IF NOT EXISTS seed_expires_at TIMESTAMPTZ;

COMMENT ON COLUMN public.feed_sessions.session_seed IS
  'Frozen per-session seed used for deterministic feed shuffle. Expires after 30 minutes.';
COMMENT ON COLUMN public.feed_sessions.seed_expires_at IS
  'Timestamp when the current session_seed becomes stale and should be regenerated.';

-- ── Step 2: Rewrite compute_feed_rankings() with diversity penalty ───────────

CREATE OR REPLACE FUNCTION public.compute_feed_rankings()
RETURNS INT AS $$
DECLARE v_count INT := 0;
BEGIN
  -- Step 1: Update engagement_score on creator_videos
  -- (unchanged from original — scores all approved videos)
  WITH stats AS (
    SELECT
      cv.id,
      COALESCE(AVG(vee.completion_pct), 0)       AS avg_completion,
      COALESCE(cv.like_count, 0)                  AS likes,
      COALESCE(cv.view_count, 0)                  AS views,
      COUNT(fi.video_id)::NUMERIC                 AS impressions,
      COUNT(fi.video_id) FILTER (WHERE fi.clicked) AS clicks,
      EXTRACT(EPOCH FROM (now() - cv.created_at)) / 3600.0 AS hours_old,
      COALESCE(cts.trust_score, 0.5)              AS trust_score
    FROM public.creator_videos cv
    LEFT JOIN public.video_engagement_events vee ON vee.video_id = cv.id
      AND vee.created_at >= now() - interval '7 days'
    LEFT JOIN public.feed_impressions fi ON fi.video_id = cv.id
      AND fi.shown_at >= now() - interval '7 days'
    LEFT JOIN public.creator_trust_scores cts ON cts.creator_id = cv.creator_id
    WHERE cv.status = 'approved' AND cv.deleted_at IS NULL
      AND (cv.suppress_until IS NULL OR cv.suppress_until < now())
    GROUP BY cv.id, cv.like_count, cv.view_count, cv.created_at, cts.trust_score
  ),
  normalized AS (
    SELECT id,
      CASE WHEN MAX(avg_completion) OVER () > 0 THEN avg_completion / MAX(avg_completion) OVER () ELSE 0 END AS n_completion,
      CASE WHEN MAX(likes) OVER () > 0 THEN LN(1 + likes) / LN(1 + MAX(likes) OVER ()) ELSE 0 END            AS n_log_likes,
      1.0 / (1.0 + hours_old / 168.0)                                                                          AS n_recency,
      CASE WHEN impressions > 0 THEN clicks / impressions ELSE 0 END                                           AS n_ctr,
      trust_score                                                                                               AS n_trust,
      -- Cold-start boost: decays over first 24h
      CASE WHEN hours_old < 24 THEN (24 - hours_old) / 24.0 * 0.20 ELSE 0 END                                 AS boost
    FROM stats
  ),
  scored AS (
    SELECT id,
      LEAST(1.0, GREATEST(0.0,
        0.30 * n_completion + 0.25 * n_log_likes + 0.20 * n_recency
        + 0.15 * n_ctr + 0.10 * n_trust + boost
      )) AS score
    FROM normalized
  )
  UPDATE public.creator_videos cv
  SET engagement_score = s.score, updated_at = now()
  FROM scored s WHERE cv.id = s.id;

  -- Step 2: Apply creator diversity penalty
  -- Penalize a creator's 3rd, 4th, ... videos so they don't dominate the feed.
  WITH creator_ranked AS (
    SELECT
      cv.id,
      cv.creator_id,
      cv.engagement_score,
      ROW_NUMBER() OVER (
        PARTITION BY cv.creator_id
        ORDER BY cv.engagement_score DESC
      ) AS creator_rank
    FROM public.creator_videos cv
    WHERE cv.status = 'approved'
      AND cv.deleted_at IS NULL
      AND (cv.suppress_until IS NULL OR cv.suppress_until < now())
  )
  UPDATE public.creator_videos cv
  SET engagement_score = cv.engagement_score * (
    CASE
      WHEN cr.creator_rank <= 2 THEN 1.0   -- Top 2 keep full score
      WHEN cr.creator_rank = 3  THEN 0.6   -- 3rd video: 60%
      ELSE 0.3                              -- 4th+: 30%
    END
  )
  FROM creator_ranked cr
  WHERE cv.id = cr.id
    AND cr.creator_rank > 2;  -- Only update videos that actually need penalty

  -- Step 3: Snapshot scores (after diversity penalty)
  INSERT INTO public.video_score_snapshots (video_id, score, computed_at)
  SELECT id, engagement_score, now() FROM public.creator_videos
  WHERE status = 'approved' AND deleted_at IS NULL;

  -- Step 4: Rebuild feed_rankings for each category
  -- rank_position is now the stable cursor target for pagination
  INSERT INTO public.feed_rankings (video_id, category, rank_position, computed_at)
  SELECT cv.id, fc.value, ROW_NUMBER() OVER (PARTITION BY fc.value ORDER BY cv.engagement_score DESC), now()
  FROM public.creator_videos cv
  CROSS JOIN public.feed_categories fc
  WHERE cv.status = 'approved' AND cv.deleted_at IS NULL
    AND (cv.suppress_until IS NULL OR cv.suppress_until < now())
  ON CONFLICT (video_id, category) DO UPDATE
    SET rank_position = EXCLUDED.rank_position, computed_at = now();

  -- Step 5: Clean up stale rankings for videos that are no longer eligible
  DELETE FROM public.feed_rankings fr
  WHERE NOT EXISTS (
    SELECT 1 FROM public.creator_videos cv
    WHERE cv.id = fr.video_id
      AND cv.status = 'approved'
      AND cv.deleted_at IS NULL
      AND (cv.suppress_until IS NULL OR cv.suppress_until < now())
  );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
