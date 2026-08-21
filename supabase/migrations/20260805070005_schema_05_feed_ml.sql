-- ============================================================================
-- SCHEMA GROUP 5: ML Ranking, Feed & Counter Engine
-- ML feature store, user affinity, feed ranking RPCs, counter flush,
-- decoupled counter events, personalized feed, video interactions RPCs
-- ============================================================================

-- ── ML Feature Store ──────────────────────────────────────────────────────────

CREATE TABLE public.video_score_snapshots (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id    UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  score       NUMERIC(10,4) NOT NULL DEFAULT 0,
  -- Feature breakdown
  completion_score  NUMERIC(5,4) DEFAULT 0,
  like_score        NUMERIC(5,4) DEFAULT 0,
  recency_score     NUMERIC(5,4) DEFAULT 0,
  ctr_score         NUMERIC(5,4) DEFAULT 0,
  trust_score       NUMERIC(5,4) DEFAULT 0,
  computed_at TIMESTAMPTZ DEFAULT now()
);

-- Retention: only keep last 30 days — see cron job in group 7
CREATE INDEX idx_vss_video_computed ON public.video_score_snapshots(video_id, computed_at DESC);

ALTER TABLE public.video_score_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins view score snapshots" ON public.video_score_snapshots FOR SELECT USING (public.is_admin_or_reviewer());

-- ── User Affinity ─────────────────────────────────────────────────────────────

CREATE TABLE public.user_affinity (
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  creator_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  affinity_score  NUMERIC(10,4) DEFAULT 0,
  total_views     INT DEFAULT 0,
  total_likes     INT DEFAULT 0,
  total_comments  INT DEFAULT 0,
  total_shares    INT DEFAULT 0,
  last_interacted TIMESTAMPTZ DEFAULT now(),
  computed_at     TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, creator_id)
);

CREATE INDEX idx_ua_user_score ON public.user_affinity(user_id, affinity_score DESC);

ALTER TABLE public.user_affinity ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own affinity"  ON public.user_affinity FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins view all affinity" ON public.user_affinity FOR SELECT USING (public.is_admin_or_reviewer());

-- ── Creator Trust Scores ──────────────────────────────────────────────────────

CREATE TABLE public.creator_trust_scores (
  creator_id             UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  trust_score            NUMERIC(5,4) DEFAULT 0.50 CHECK (trust_score BETWEEN 0 AND 1),
  approval_rate          NUMERIC(5,4) DEFAULT 1.0,
  total_uploads          INT DEFAULT 0,
  total_approved         INT DEFAULT 0,
  total_rejected         INT DEFAULT 0,
  total_removed          INT DEFAULT 0,
  abuse_reports_received INT DEFAULT 0,
  avg_completion_rate    NUMERIC(5,4) DEFAULT 0,
  auto_approve_eligible  BOOLEAN DEFAULT false,
  computed_at            TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.creator_trust_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Creators view own trust scores" ON public.creator_trust_scores FOR SELECT USING (auth.uid() = creator_id);
CREATE POLICY "Admins view all trust scores"   ON public.creator_trust_scores FOR SELECT USING (public.is_admin_or_reviewer());

-- ── Decoupled Counter Events ──────────────────────────────────────────────────
-- Write-optimised: no FK on video_id for maximum write throughput.
-- Flushed every 30s by pg_cron → flush_counter_events().

CREATE TABLE public.video_counter_events (
  id         BIGINT GENERATED ALWAYS AS IDENTITY,
  video_id   UUID NOT NULL,
  counter    TEXT NOT NULL CHECK (counter IN ('like','comment','view','share')),
  delta      INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_vce_unflushed ON public.video_counter_events(video_id);

ALTER TABLE public.video_counter_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth insert counter events" ON public.video_counter_events FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- ── Counter Flush RPC ─────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.flush_counter_events()
RETURNS JSONB AS $$
DECLARE
  v_flushed INT := 0;
  v_max_id  BIGINT;
BEGIN
  SELECT MAX(id) INTO v_max_id FROM public.video_counter_events;
  IF v_max_id IS NULL THEN RETURN jsonb_build_object('flushed', 0); END IF;

  -- Apply like deltas
  UPDATE public.creator_videos cv SET
    like_count = like_count + agg.total_delta
  FROM (
    SELECT video_id, SUM(delta) AS total_delta FROM public.video_counter_events
    WHERE counter = 'like' AND id <= v_max_id GROUP BY video_id
  ) agg WHERE cv.id = agg.video_id;

  -- Apply comment deltas
  UPDATE public.creator_videos cv SET
    comment_count = comment_count + agg.total_delta
  FROM (
    SELECT video_id, SUM(delta) AS total_delta FROM public.video_counter_events
    WHERE counter = 'comment' AND id <= v_max_id GROUP BY video_id
  ) agg WHERE cv.id = agg.video_id;

  -- Apply view deltas
  UPDATE public.creator_videos cv SET
    view_count = view_count + agg.total_delta
  FROM (
    SELECT video_id, SUM(delta) AS total_delta FROM public.video_counter_events
    WHERE counter = 'view' AND id <= v_max_id GROUP BY video_id
  ) agg WHERE cv.id = agg.video_id;

  -- Apply share deltas
  UPDATE public.creator_videos cv SET
    share_count = share_count + agg.total_delta
  FROM (
    SELECT video_id, SUM(delta) AS total_delta FROM public.video_counter_events
    WHERE counter = 'share' AND id <= v_max_id GROUP BY video_id
  ) agg WHERE cv.id = agg.video_id;

  DELETE FROM public.video_counter_events WHERE id <= v_max_id;
  GET DIAGNOSTICS v_flushed = ROW_COUNT;
  RETURN jsonb_build_object('flushed', v_flushed, 'max_id', v_max_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Compute Feed Rankings ─────────────────────────────────────────────────────
-- Nightly / 15-min batch: scores all approved videos and rebuilds feed_rankings.
-- Weights: 0.30 completion + 0.25 log-likes + 0.20 recency + 0.15 CTR + 0.10 trust

CREATE OR REPLACE FUNCTION public.compute_feed_rankings()
RETURNS INT AS $$
DECLARE v_count INT := 0;
BEGIN
  -- Step 1: Update engagement_score on creator_videos
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
      -- Normalize each feature 0..1 within the current candidate pool
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

  -- Step 2: Snapshot scores
  INSERT INTO public.video_score_snapshots (video_id, score, computed_at)
  SELECT id, engagement_score, now() FROM public.creator_videos
  WHERE status = 'approved' AND deleted_at IS NULL;

  -- Step 3: Rebuild feed_rankings for each category
  INSERT INTO public.feed_rankings (video_id, category, rank_position, computed_at)
  SELECT cv.id, fc.value, ROW_NUMBER() OVER (PARTITION BY fc.value ORDER BY cv.engagement_score DESC), now()
  FROM public.creator_videos cv
  CROSS JOIN public.feed_categories fc
  WHERE cv.status = 'approved' AND cv.deleted_at IS NULL
    AND (cv.suppress_until IS NULL OR cv.suppress_until < now())
  ON CONFLICT (video_id, category) DO UPDATE
    SET rank_position = EXCLUDED.rank_position, computed_at = now();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Compute Creator Trust Scores ──────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.compute_creator_trust_scores()
RETURNS INT AS $$
DECLARE v_count INT := 0;
BEGIN
  INSERT INTO public.creator_trust_scores (
    creator_id, total_uploads, total_approved, total_rejected, total_removed,
    approval_rate, abuse_reports_received, avg_completion_rate,
    trust_score, auto_approve_eligible, computed_at
  )
  SELECT
    cv.creator_id,
    COUNT(*)::int,
    COUNT(*) FILTER (WHERE cv.status = 'approved')::int,
    COUNT(*) FILTER (WHERE cv.status = 'rejected')::int,
    COUNT(*) FILTER (WHERE cv.status = 'removed')::int,
    CASE WHEN COUNT(*) > 0 THEN COUNT(*) FILTER (WHERE cv.status = 'approved')::numeric / COUNT(*) ELSE 0 END,
    COALESCE(SUM(cv.report_count), 0)::int,
    COALESCE(AVG(cv.avg_completion_pct) FILTER (WHERE cv.status = 'approved'), 0),
    LEAST(1.0, GREATEST(0.0,
      0.50 * (CASE WHEN COUNT(*) > 0 THEN COUNT(*) FILTER (WHERE cv.status = 'approved')::numeric / COUNT(*) ELSE 0 END)
      + 0.30 * COALESCE(AVG(cv.avg_completion_pct) FILTER (WHERE cv.status = 'approved'), 0)
      + 0.20 * (1.0 - LEAST(1.0, COALESCE(SUM(cv.report_count), 0)::numeric / GREATEST(COUNT(*), 1)))
    )),
    (COUNT(*) >= 10
      AND COUNT(*) FILTER (WHERE cv.status = 'approved')::numeric / GREATEST(COUNT(*), 1) > 0.85
      AND COALESCE(SUM(cv.report_count), 0) < 3
    ),
    now()
  FROM public.creator_videos cv
  WHERE cv.deleted_at IS NULL
  GROUP BY cv.creator_id
  ON CONFLICT (creator_id) DO UPDATE SET
    total_uploads          = EXCLUDED.total_uploads,
    total_approved         = EXCLUDED.total_approved,
    total_rejected         = EXCLUDED.total_rejected,
    total_removed          = EXCLUDED.total_removed,
    approval_rate          = EXCLUDED.approval_rate,
    abuse_reports_received = EXCLUDED.abuse_reports_received,
    avg_completion_rate    = EXCLUDED.avg_completion_rate,
    trust_score            = EXCLUDED.trust_score,
    auto_approve_eligible  = EXCLUDED.auto_approve_eligible,
    computed_at            = now();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Compute Creator Daily Stats ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.compute_creator_daily_stats(p_date DATE DEFAULT CURRENT_DATE)
RETURNS INT AS $$
DECLARE v_count INT := 0;
BEGIN
  INSERT INTO public.creator_daily_stats (
    creator_id, date, total_views, total_watch_time,
    total_likes, total_comments, videos_uploaded, avg_completion_rate
  )
  SELECT
    cv.creator_id, p_date,
    COALESCE(SUM(vds.total_views), 0)::int,
    COALESCE(SUM(vds.total_watch_time), 0),
    SUM(cv.like_count)::int,
    SUM(cv.comment_count)::int,
    COUNT(*) FILTER (WHERE cv.created_at::date = p_date)::int,
    COALESCE(AVG(cv.avg_completion_pct) FILTER (WHERE cv.view_count > 0), 0)
  FROM public.creator_videos cv
  LEFT JOIN public.video_daily_stats vds ON vds.video_id = cv.id AND vds.date = p_date
  WHERE cv.deleted_at IS NULL AND cv.status = 'approved'
  GROUP BY cv.creator_id
  ON CONFLICT (creator_id, date) DO UPDATE SET
    total_views         = EXCLUDED.total_views,
    total_watch_time    = EXCLUDED.total_watch_time,
    total_likes         = EXCLUDED.total_likes,
    total_comments      = EXCLUDED.total_comments,
    videos_uploaded     = EXCLUDED.videos_uploaded,
    avg_completion_rate = EXCLUDED.avg_completion_rate;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Compute Trending Hashtags ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.compute_trending_hashtags()
RETURNS VOID AS $$
BEGIN
  UPDATE public.hashtags h SET
    trending_score = COALESCE(recent.cnt, 0)::numeric / (COALESCE(weekly.avg_cnt, 0) + 1)
  FROM (
    SELECT vh.hashtag_id, COUNT(*) AS cnt
    FROM public.video_hashtags vh
    JOIN public.creator_videos cv ON cv.id = vh.video_id
    WHERE cv.created_at >= now() - interval '24 hours'
      AND cv.status = 'approved' AND cv.deleted_at IS NULL
    GROUP BY vh.hashtag_id
  ) recent
  LEFT JOIN (
    SELECT vh.hashtag_id, COUNT(*)::numeric / 7 AS avg_cnt
    FROM public.video_hashtags vh
    JOIN public.creator_videos cv ON cv.id = vh.video_id
    WHERE cv.created_at >= now() - interval '7 days'
      AND cv.status = 'approved' AND cv.deleted_at IS NULL
    GROUP BY vh.hashtag_id
  ) weekly ON weekly.hashtag_id = recent.hashtag_id
  WHERE h.id = recent.hashtag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Creator profile grid (cursor-based)
CREATE OR REPLACE FUNCTION public.get_creator_videos_page(
  p_creator_id UUID,
  p_cursor     TIMESTAMPTZ DEFAULT NULL,
  p_limit      INT DEFAULT 18
) RETURNS TABLE (
  video_id         UUID,
  title            TEXT,
  thumbnail_url    TEXT,
  view_count       INT,
  like_count       INT,
  duration_seconds INT,
  mux_playback_id  TEXT,
  mux_status       TEXT,
  created_at       TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT cv.id, cv.title, cv.thumbnail_url,
    cv.view_count, cv.like_count, cv.duration_seconds,
    cv.mux_playback_id, cv.mux_status, cv.created_at
  FROM public.creator_videos cv
  WHERE cv.creator_id = p_creator_id
    AND cv.status = 'approved' AND cv.deleted_at IS NULL
    AND (p_cursor IS NULL OR cv.created_at < p_cursor)
  ORDER BY cv.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Feed analytics for users
CREATE OR REPLACE FUNCTION public.get_user_feed_analytics(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
  total_videos_watched      INT,
  total_watch_time_seconds  INT,
  average_completion_rate   NUMERIC,
  videos_skipped            INT,
  videos_liked              INT,
  videos_shared             INT,
  top_genres                TEXT[]
) AS $$
DECLARE v_uid UUID := COALESCE(p_user_id, auth.uid());
BEGIN
  RETURN QUERY
  WITH user_stats AS (
    SELECT
      count(*)::INT AS total_watched,
      (sum(watch_time_ms) / 1000)::INT AS total_time_sec,
      avg(CASE WHEN duration_ms > 0 THEN LEAST(watch_time_ms::numeric / duration_ms::numeric, 1.0) ELSE 0 END) AS avg_completion,
      count(*) FILTER (WHERE skipped = TRUE)::INT AS total_skipped,
      count(*) FILTER (WHERE liked   = TRUE)::INT AS total_liked,
      count(*) FILTER (WHERE shared  = TRUE)::INT AS total_shared
    FROM public.video_interactions WHERE user_id = v_uid
  ),
  ranked_genres AS (
    SELECT trim(unnest(string_to_array(genre, ','))) AS genre_name, count(*) AS cnt
    FROM public.user_titles WHERE user_id = v_uid AND genre IS NOT NULL
    GROUP BY genre_name ORDER BY cnt DESC LIMIT 3
  )
  SELECT
    us.total_watched,
    COALESCE(us.total_time_sec, 0),
    COALESCE(us.avg_completion, 0.0),
    us.total_skipped, us.total_liked, us.total_shared,
    COALESCE((SELECT array_agg(genre_name) FROM ranked_genres), '{}'::TEXT[])
  FROM user_stats us;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Atomic RPCs
CREATE OR REPLACE FUNCTION public.increment_video_views(p_video_id UUID)
RETURNS void AS $$
  UPDATE public.creator_videos SET view_count = view_count + 1 WHERE id = p_video_id;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_video_likes(p_video_id UUID)
RETURNS void AS $$
  UPDATE public.creator_videos SET like_count = like_count + 1 WHERE id = p_video_id;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.decrement_video_likes(p_video_id UUID)
RETURNS void AS $$
  UPDATE public.creator_videos SET like_count = GREATEST(like_count - 1, 0) WHERE id = p_video_id;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_video_shares(p_video_id UUID)
RETURNS void AS $$
  UPDATE public.creator_videos SET share_count = share_count + 1 WHERE id = p_video_id;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.append_seen_videos(p_session_id UUID, p_new_ids UUID[])
RETURNS void AS $$
  UPDATE public.feed_sessions
  SET seen_video_ids = (SELECT array_agg(DISTINCT u) FROM unnest(seen_video_ids || p_new_ids) u),
      updated_at = now()
  WHERE id = p_session_id;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.upsert_video_interaction(
  p_video_id      UUID,
  p_watch_time_ms INT,
  p_duration_ms   INT,
  p_completed     BOOLEAN DEFAULT FALSE,
  p_skipped       BOOLEAN DEFAULT FALSE,
  p_rewatched     BOOLEAN DEFAULT FALSE
) RETURNS void AS $$
BEGIN
  INSERT INTO public.video_interactions (
    user_id, video_id, watch_time_ms, duration_ms, completed, skipped, rewatched
  ) VALUES (
    auth.uid(), p_video_id, p_watch_time_ms, p_duration_ms, p_completed, p_skipped, p_rewatched
  )
  ON CONFLICT (user_id, video_id) DO UPDATE SET
    watch_time_ms = GREATEST(video_interactions.watch_time_ms, EXCLUDED.watch_time_ms),
    duration_ms   = EXCLUDED.duration_ms,
    completed     = video_interactions.completed OR EXCLUDED.completed,
    skipped       = EXCLUDED.skipped,
    rewatched     = video_interactions.rewatched OR EXCLUDED.rewatched,
    updated_at    = NOW();

  IF p_watch_time_ms > 2000 THEN
    UPDATE public.feed_impressions
    SET watched = TRUE
    WHERE user_id = auth.uid() AND video_id = p_video_id AND watched = FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.batch_insert_impressions(p_impressions JSONB)
RETURNS void AS $$
BEGIN
  INSERT INTO public.feed_impressions (user_id, video_id, position, feed_source)
  SELECT auth.uid(), (item->>'video_id')::UUID, (item->>'position')::INT, item->>'feed_source'
  FROM jsonb_array_elements(p_impressions) AS item
  ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
