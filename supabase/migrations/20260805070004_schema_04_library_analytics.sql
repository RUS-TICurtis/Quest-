-- ============================================================================
-- SCHEMA GROUP 4: Library, Analytics & Notifications
-- User library, ratings, recommendations, feed ranking tables,
-- analytics tables, notifications, reports
-- ============================================================================

-- ── User Library ──────────────────────────────────────────────────────────────

CREATE TABLE public.user_titles (
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title_id    TEXT NOT NULL,
  media_type  TEXT NOT NULL REFERENCES public.media_types(value),
  title       TEXT NOT NULL,
  poster_path TEXT,
  genre       TEXT,
  rating      INT CHECK (rating BETWEEN 1 AND 10),
  status      TEXT REFERENCES public.user_title_statuses(value),
  is_favorite BOOLEAN DEFAULT false,
  rated_at    TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, title_id, media_type)
);

CREATE INDEX idx_ut_user_status ON public.user_titles(user_id, status);
CREATE INDEX idx_ut_title       ON public.user_titles(title_id, media_type);

CREATE TRIGGER handle_ut_updated_at
  BEFORE UPDATE ON public.user_titles FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

ALTER TABLE public.user_titles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read user titles" ON public.user_titles FOR SELECT USING (true);
CREATE POLICY "Users manage own titles" ON public.user_titles FOR ALL USING (auth.uid() = user_id);

-- ── User Ratings ──────────────────────────────────────────────────────────────

CREATE TABLE public.user_ratings (
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title_id   TEXT NOT NULL,
  rating     INT NOT NULL CHECK (rating BETWEEN 1 AND 10),
  source     TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, title_id, created_at)
);

CREATE INDEX idx_ur_user  ON public.user_ratings(user_id, created_at DESC);
CREATE INDEX idx_ur_title ON public.user_ratings(title_id);

ALTER TABLE public.user_ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read ratings"  ON public.user_ratings FOR SELECT USING (true);
CREATE POLICY "Users manage ratings" ON public.user_ratings FOR ALL USING (auth.uid() = user_id);

-- ── Recommendations ───────────────────────────────────────────────────────────

CREATE TABLE public.recommendations (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  to_user_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  movie_id     TEXT NOT NULL,
  media_type   TEXT REFERENCES public.media_types(value),
  title        TEXT,
  poster_path  TEXT,
  message      TEXT,
  status       TEXT DEFAULT 'unread',
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_rec_to_user ON public.recommendations(to_user_id, created_at DESC);

ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own recommendations" ON public.recommendations FOR SELECT
  USING (auth.uid() = to_user_id OR auth.uid() = from_user_id);
CREATE POLICY "Users send recommendations"     ON public.recommendations FOR INSERT
  WITH CHECK (auth.uid() = from_user_id);
CREATE POLICY "Users update received"          ON public.recommendations FOR UPDATE
  USING (auth.uid() = to_user_id);

-- ── Seen History ──────────────────────────────────────────────────────────────

CREATE TABLE public.seen_history (
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title_id   TEXT NOT NULL,
  media_type TEXT NOT NULL REFERENCES public.media_types(value),
  seen_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, title_id, media_type)
);

ALTER TABLE public.seen_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage seen" ON public.seen_history FOR ALL USING (auth.uid() = user_id);

-- ── Feed Cache ────────────────────────────────────────────────────────────────

CREATE TABLE public.feed_cache (
  user_id      UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  videos       JSONB NOT NULL,
  last_updated TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.feed_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own cache"   ON public.feed_cache FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own cache" ON public.feed_cache FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own cache" ON public.feed_cache FOR UPDATE USING (auth.uid() = user_id);

-- ── Feed Rankings ─────────────────────────────────────────────────────────────

CREATE TABLE public.feed_rankings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id      UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  category      TEXT DEFAULT 'for_you' REFERENCES public.feed_categories(value),
  rank_position INT NOT NULL,
  computed_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE (video_id, category)
);

-- Covering index — index-only scan for feed queries
CREATE INDEX idx_fr_cat_rank_vid ON public.feed_rankings(category, rank_position) INCLUDE (video_id, computed_at);

ALTER TABLE public.feed_rankings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read rankings"  ON public.feed_rankings FOR SELECT USING (true);
CREATE POLICY "Admins manage rankings" ON public.feed_rankings FOR ALL USING (public.is_admin_or_reviewer());

-- ── Feed Impressions (Partitioned) ────────────────────────────────────────────

CREATE TABLE public.feed_impressions (
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  video_id    UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  position    INT DEFAULT 0,
  feed_source TEXT DEFAULT 'explore',
  clicked     BOOLEAN DEFAULT false,
  watched     BOOLEAN DEFAULT false,
  shown_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, video_id, shown_at)
) PARTITION BY RANGE (shown_at);

CREATE TABLE public.fi_default PARTITION OF public.feed_impressions DEFAULT;
CREATE TABLE public.fi_2025_02 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE public.fi_2025_03 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE public.fi_2025_04 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE public.fi_2025_05 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE public.fi_2025_06 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE public.fi_2025_07 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE public.fi_2025_08 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE public.fi_2025_09 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE public.fi_2025_10 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE public.fi_2025_11 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE public.fi_2025_12 PARTITION OF public.feed_impressions FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE public.fi_2026_01 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE public.fi_2026_02 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE public.fi_2026_03 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE public.fi_2026_04 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE public.fi_2026_05 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE public.fi_2026_06 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE public.fi_2026_07 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE public.fi_2026_08 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE public.fi_2026_09 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE public.fi_2026_10 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE public.fi_2026_11 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE public.fi_2026_12 PARTITION OF public.feed_impressions FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

CREATE INDEX idx_fi_user_shown ON public.feed_impressions(user_id, shown_at DESC);
CREATE INDEX idx_fi_video      ON public.feed_impressions(video_id);
CREATE INDEX idx_fi_feed_source ON public.feed_impressions(feed_source);

ALTER TABLE public.feed_impressions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own impressions" ON public.feed_impressions FOR ALL USING (auth.uid() = user_id);

-- ── Feed Sessions ─────────────────────────────────────────────────────────────

CREATE TABLE public.feed_sessions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seen_video_ids UUID[] DEFAULT '{}',
  last_cursor    UUID,
  updated_at     TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id)
);

ALTER TABLE public.feed_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own sessions" ON public.feed_sessions FOR ALL USING (auth.uid() = user_id);

-- ── Video Interactions ────────────────────────────────────────────────────────

CREATE TABLE public.video_interactions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  video_id     UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  watch_time_ms INT DEFAULT 0,
  duration_ms   INT DEFAULT 0,
  completed     BOOLEAN DEFAULT FALSE,
  liked         BOOLEAN DEFAULT FALSE,
  commented     BOOLEAN DEFAULT FALSE,
  shared        BOOLEAN DEFAULT FALSE,
  skipped       BOOLEAN DEFAULT FALSE,
  rewatched     BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, video_id)
);

CREATE INDEX idx_vi_user      ON public.video_interactions(user_id);
CREATE INDEX idx_vi_video     ON public.video_interactions(video_id);
CREATE INDEX idx_vi_user_liked ON public.video_interactions(user_id) WHERE liked = TRUE;

ALTER TABLE public.video_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own interactions"           ON public.video_interactions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Creators view interactions on their videos" ON public.video_interactions FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.creator_videos WHERE id = video_id AND creator_id = auth.uid())
);

-- ── Analytics Tables ──────────────────────────────────────────────────────────

CREATE TABLE public.video_daily_stats (
  video_id           UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  date               DATE NOT NULL,
  total_views        INT DEFAULT 0,
  total_watch_time   BIGINT DEFAULT 0,
  sum_completion_pct NUMERIC(12,4) DEFAULT 0,
  PRIMARY KEY (video_id, date)
);

CREATE INDEX idx_vds_date ON public.video_daily_stats(date);

ALTER TABLE public.video_daily_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Creators view own video stats" ON public.video_daily_stats FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.creator_videos WHERE id = video_id AND creator_id = auth.uid())
);
CREATE POLICY "Admins view all video stats" ON public.video_daily_stats FOR SELECT USING (public.is_admin_or_reviewer());

CREATE OR REPLACE FUNCTION public.update_video_daily_stats()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.video_daily_stats (video_id, date, total_views, total_watch_time, sum_completion_pct)
  VALUES (NEW.video_id, CURRENT_DATE, 1, NEW.watch_duration_seconds, NEW.completion_pct)
  ON CONFLICT (video_id, date) DO UPDATE SET
    total_views        = public.video_daily_stats.total_views + 1,
    total_watch_time   = public.video_daily_stats.total_watch_time + EXCLUDED.total_watch_time,
    sum_completion_pct = public.video_daily_stats.sum_completion_pct + EXCLUDED.sum_completion_pct;
  UPDATE public.creator_videos SET view_count = view_count + 1 WHERE id = NEW.video_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_engagement_event
  AFTER INSERT ON public.video_engagement_events
  FOR EACH ROW EXECUTE FUNCTION public.update_video_daily_stats();

CREATE TABLE public.user_daily_stats (
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date            DATE NOT NULL,
  videos_watched  INT DEFAULT 0,
  minutes_watched INT DEFAULT 0,
  posts_made      INT DEFAULT 0,
  PRIMARY KEY (user_id, date)
);

ALTER TABLE public.user_daily_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own daily stats" ON public.user_daily_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins view daily stats"    ON public.user_daily_stats FOR SELECT USING (public.is_admin_or_reviewer());

CREATE TABLE public.analytics_events (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES auth.users(id),
  event_name TEXT NOT NULL,
  parameters JSONB,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_ae_user_created ON public.analytics_events(user_id, created_at DESC);
CREATE INDEX idx_ae_event        ON public.analytics_events(event_name);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users insert own events" ON public.analytics_events FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users view own events"   ON public.analytics_events FOR SELECT USING (auth.uid() = user_id);

CREATE TABLE public.creator_daily_stats (
  creator_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  date                DATE NOT NULL,
  new_followers       INT DEFAULT 0,
  total_views         INT DEFAULT 0,
  total_watch_time    BIGINT DEFAULT 0,
  total_likes         INT DEFAULT 0,
  total_comments      INT DEFAULT 0,
  total_shares        INT DEFAULT 0,
  videos_uploaded     INT DEFAULT 0,
  avg_completion_rate NUMERIC(5,4) DEFAULT 0,
  estimated_cpm       NUMERIC(10,4) DEFAULT 0,
  PRIMARY KEY (creator_id, date)
);

CREATE INDEX idx_cds_date ON public.creator_daily_stats(date);

ALTER TABLE public.creator_daily_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Creators view own daily stats" ON public.creator_daily_stats FOR SELECT USING (auth.uid() = creator_id);
CREATE POLICY "Admins view all daily stats"   ON public.creator_daily_stats FOR SELECT USING (public.is_admin_or_reviewer());

CREATE TABLE public.video_retention_buckets (
  video_id     UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  bucket_pct   INT NOT NULL CHECK (bucket_pct IN (10, 20, 30, 40, 50, 60, 70, 80, 90, 100)),
  viewer_count INT DEFAULT 0,
  avg_rewatch  NUMERIC(5,2) DEFAULT 1.0,
  PRIMARY KEY (video_id, bucket_pct)
);

ALTER TABLE public.video_retention_buckets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Creators view own retention" ON public.video_retention_buckets FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.creator_videos WHERE id = video_id AND creator_id = auth.uid())
);
CREATE POLICY "Admins view all retention" ON public.video_retention_buckets FOR SELECT USING (public.is_admin_or_reviewer());

-- ── Notifications ─────────────────────────────────────────────────────────────

CREATE TABLE public.notifications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type          TEXT NOT NULL,
  title         TEXT,
  body          TEXT,
  image_url     TEXT,
  metadata      JSONB DEFAULT '{}'::jsonb,
  reference_id  UUID,
  reference_url TEXT,
  is_read       BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notif_user_read    ON public.notifications(user_id, is_read);
CREATE INDEX idx_notif_user_created ON public.notifications(user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users mark read"              ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
-- FIX: was open to any authenticated user; now restricted to own-user
-- Service role (Edge Functions) inserts notifications for others using service_role key which bypasses RLS
CREATE POLICY "Users insert own notifications" ON public.notifications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ── Reports (Universal) ───────────────────────────────────────────────────────

CREATE TABLE public.reports (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  target_id        UUID,                   -- nullable: communities use target_id_int
  target_id_int    BIGINT,                 -- for BIGINT targets (communities)
  target_type      TEXT NOT NULL REFERENCES public.report_types(value),
  reason           TEXT NOT NULL,
  additional_info  TEXT,
  content_snapshot JSONB,
  reported_user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  severity         TEXT DEFAULT 'low',
  report_weight    NUMERIC DEFAULT 1.0,
  status           TEXT DEFAULT 'pending' REFERENCES public.report_statuses(value),
  reviewed_by      UUID REFERENCES public.profiles(id),
  review_notes     TEXT,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_reports_status ON public.reports(status);
CREATE INDEX idx_reports_target ON public.reports(target_type, target_id);
CREATE INDEX idx_reports_user   ON public.reports(reported_user_id) WHERE reported_user_id IS NOT NULL;

CREATE TRIGGER handle_reports_updated_at
  BEFORE UPDATE ON public.reports FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users submit reports"    ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Users view own reports"  ON public.reports FOR SELECT USING (auth.uid() = reporter_id);
CREATE POLICY "Admins view all reports" ON public.reports FOR SELECT USING (public.is_admin_or_reviewer());
CREATE POLICY "Admins update reports"   ON public.reports FOR UPDATE USING (public.is_admin_or_reviewer());
