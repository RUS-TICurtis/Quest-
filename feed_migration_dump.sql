CREATE TABLE public.community_posts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id     BIGINT REFERENCES public.communities(id) ON DELETE CASCADE,
  show_id          INT,
  -- FIX: was nullable, enabling ghost/anonymous posts — now NOT NULL
  author_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content          TEXT,
  media_urls       TEXT[],
  media_types      TEXT[],
  hashtags         TEXT[],
  is_spoiler       BOOLEAN DEFAULT false,
  is_hidden        BOOLEAN DEFAULT false,
  is_locked        BOOLEAN DEFAULT false,   -- added in migration 21
  pinned_at        TIMESTAMPTZ,             -- added in migration 21
  score            INT DEFAULT 0,
  upvotes          INT DEFAULT 0,
  downvotes        INT DEFAULT 0,
  comment_count    INT DEFAULT 0,
  view_count       INT DEFAULT 0,
  deleted_at       TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now(),
  last_activity_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.creator_videos (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id               UUID NOT NULL CONSTRAINT creator_videos_creator_id_fkey REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- Media
  video_url                TEXT NOT NULL,
  thumbnail_url            TEXT,
  -- FIX: duration_seconds is nullable because Mux reports real duration post-encode
  duration_seconds         INT CHECK (duration_seconds IS NULL OR duration_seconds > 0),
  aspect_ratio             TEXT DEFAULT '9:16',
  -- Mux HLS (added in migration 20260402120000)
  mux_asset_id             TEXT,
  mux_playback_id          TEXT,
  mux_status               TEXT DEFAULT 'processing'
    CHECK (mux_status IN ('processing','ready','errored')),
  mux_duration_seconds     NUMERIC,
  -- TMDB Linking
  tmdb_id                  INT,
  tmdb_type                TEXT CHECK (tmdb_type IS NULL OR tmdb_type IN ('movie', 'tv')),
  tmdb_title               TEXT,
  -- Metadata
  title                    TEXT,
  description              TEXT,
  tags                     TEXT[],
  spoiler                  BOOLEAN DEFAULT false,
  -- A/B testing
  alt_title                TEXT,
  alt_thumbnail_url        TEXT,
  -- Moderation
  status                   TEXT DEFAULT 'pending'
    CHECK (status IN ('pending','approved','rejected','removed','processing','ready')),
  moderation_flags         JSONB DEFAULT '{}',
  auto_quality_score       NUMERIC(5,4),
  report_count             INT DEFAULT 0,
  reviewed_by              UUID REFERENCES public.profiles(id),
  reviewed_at              TIMESTAMPTZ,
  rejection_reason         TEXT,
  -- Feed control
  suppress_until           TIMESTAMPTZ,
  boost_until              TIMESTAMPTZ DEFAULT (now() + interval '24 hours'),
  -- Counters (denormalized, maintained by triggers + flush_counter_events)
  view_count               INT DEFAULT 0,
  like_count               INT DEFAULT 0,
  comment_count            INT DEFAULT 0,
  share_count              INT DEFAULT 0,
  total_watch_time_seconds INT DEFAULT 0,
  avg_completion_pct       NUMERIC(5,4) DEFAULT 0 CHECK (avg_completion_pct BETWEEN 0 AND 1),
  -- Scoring
  engagement_score         NUMERIC(10,4) DEFAULT 0,
  quality_score            NUMERIC(10,4),
  -- Soft delete
  deleted_at               TIMESTAMPTZ,
  created_at               TIMESTAMPTZ DEFAULT now(),
  updated_at               TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.video_engagement_events (
  id                     UUID DEFAULT gen_random_uuid(),
  video_id               UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  user_id                UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  watch_duration_seconds INT NOT NULL CHECK (watch_duration_seconds >= 0),
  completion_pct         NUMERIC(5,4) NOT NULL CHECK (completion_pct BETWEEN 0 AND 1),
  created_at             TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

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


