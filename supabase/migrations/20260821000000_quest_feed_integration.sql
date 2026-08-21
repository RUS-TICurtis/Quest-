-- ============================================================================
-- Quest Feed & Posts Integration Migration
-- ============================================================================

-- Add missing columns to profiles for feed integration
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS role text DEFAULT 'user',
  ADD COLUMN IF NOT EXISTS creator_status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS is_banned boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_shadowbanned boolean DEFAULT false;

-- Create function needed for some RLS policies
CREATE OR REPLACE FUNCTION public.is_admin_or_reviewer()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role IN ('admin', 'reviewer')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Consolidated Quest Feed & Posts Migration

-- ── Community Posts ───────────────────────────────────────────────────────────

CREATE TABLE public.community_posts (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id     UUID REFERENCES public.communities(id) ON DELETE CASCADE,
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

CREATE INDEX idx_posts_community_created ON public.community_posts(community_id, created_at DESC);
CREATE INDEX idx_posts_author            ON public.community_posts(author_id);
CREATE INDEX idx_posts_score             ON public.community_posts(score DESC);
-- Added in migration 20260401000002
CREATE INDEX idx_posts_show_score        ON public.community_posts(show_id, score DESC);
CREATE INDEX idx_posts_show_comment_count ON public.community_posts(show_id, comment_count DESC);
CREATE INDEX idx_posts_show_created      ON public.community_posts(show_id, created_at DESC);

CREATE TRIGGER handle_posts_updated_at
  BEFORE UPDATE ON public.community_posts FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read posts"         ON public.community_posts FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "Auth create posts"         ON public.community_posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users update own posts"    ON public.community_posts FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Mods update posts" ON public.community_posts FOR UPDATE USING (public.is_admin_or_reviewer());
CREATE POLICY "Mods delete posts" ON public.community_posts FOR DELETE USING (public.is_admin_or_reviewer());

-- ── Community Comments ────────────────────────────────────────────────────────

CREATE TABLE public.community_comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  -- FIX: nullable author_id retained to allow soft-delete ghost rows on CASCADE SET NULL
  author_id  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  content    TEXT,
  parent_id  UUID REFERENCES public.community_comments(id),
  upvotes    INT DEFAULT 0,
  downvotes  INT DEFAULT 0,
  is_hidden  BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_comments_post_created ON public.community_comments(post_id, created_at DESC);
CREATE INDEX idx_comments_parent       ON public.community_comments(parent_id) WHERE parent_id IS NOT NULL;
CREATE INDEX idx_comments_author       ON public.community_comments(author_id);

CREATE TRIGGER handle_comments_updated_at
  BEFORE UPDATE ON public.community_comments FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read comments" ON public.community_comments FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "Auth create comments" ON public.community_comments FOR INSERT WITH CHECK (auth.uid() = author_id);

-- Comment count trigger
CREATE OR REPLACE FUNCTION public.handle_community_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.community_posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_community_comment_change
  AFTER INSERT OR DELETE ON public.community_comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_community_comment_count();

-- ── Creator Videos ────────────────────────────────────────────────────────────

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

-- Core indexes
CREATE INDEX idx_cv_creator         ON public.creator_videos(creator_id, created_at DESC);
CREATE INDEX idx_cv_status          ON public.creator_videos(status);
-- Hot-path feed index (partial, covering)
CREATE INDEX idx_cv_approved_score  ON public.creator_videos(engagement_score DESC)
  WHERE status = 'approved' AND deleted_at IS NULL;
CREATE INDEX idx_cv_ranked_feed     ON public.creator_videos(engagement_score DESC, created_at DESC)
  WHERE status = 'approved' AND deleted_at IS NULL;
CREATE INDEX idx_cv_creator_cursor  ON public.creator_videos(creator_id, created_at DESC, id)
  WHERE status = 'approved' AND deleted_at IS NULL;
CREATE INDEX idx_cv_tmdb            ON public.creator_videos(tmdb_id, tmdb_type) WHERE tmdb_id IS NOT NULL;
-- Moderation
CREATE INDEX idx_cv_moderation_queue ON public.creator_videos(created_at ASC)
  WHERE status = 'pending' AND deleted_at IS NULL;
CREATE INDEX idx_cv_reported        ON public.creator_videos(report_count DESC)
  WHERE report_count > 0 AND status = 'approved';
-- Mux webhook lookup
CREATE INDEX idx_cv_mux_playback    ON public.creator_videos(mux_playback_id) WHERE mux_playback_id IS NOT NULL;
-- GIN on tags
CREATE INDEX idx_cv_tags_gin        ON public.creator_videos USING GIN (tags)
  WHERE tags IS NOT NULL AND deleted_at IS NULL;

CREATE TRIGGER handle_cv_updated_at
  BEFORE UPDATE ON public.creator_videos FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

ALTER TABLE public.creator_videos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public view approved videos" ON public.creator_videos FOR SELECT
  USING (status = 'approved' AND deleted_at IS NULL);
CREATE POLICY "Creators view own videos"    ON public.creator_videos FOR SELECT
  USING (auth.uid() = creator_id);
CREATE POLICY "Creators upload videos"      ON public.creator_videos FOR INSERT WITH CHECK (
  auth.uid() = creator_id AND EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'creator' AND creator_status = 'approved'
  )
);
CREATE POLICY "Creators update own pending" ON public.creator_videos FOR UPDATE
  USING (auth.uid() = creator_id AND status IN ('pending', 'rejected'));
CREATE POLICY "Creators delete own pending" ON public.creator_videos FOR DELETE
  USING (auth.uid() = creator_id AND status IN ('pending', 'rejected'));
CREATE POLICY "Admins view all videos"      ON public.creator_videos FOR SELECT
  USING (public.is_admin_or_reviewer());
CREATE POLICY "Admins moderate videos"      ON public.creator_videos FOR UPDATE
  USING (public.is_admin_or_reviewer());

-- ── Video Engagement Events (Partitioned) ─────────────────────────────────────

CREATE TABLE public.video_engagement_events (
  id                     UUID DEFAULT gen_random_uuid(),
  video_id               UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  user_id                UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  watch_duration_seconds INT NOT NULL CHECK (watch_duration_seconds >= 0),
  completion_pct         NUMERIC(5,4) NOT NULL CHECK (completion_pct BETWEEN 0 AND 1),
  created_at             TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Default catch-all + historical partitions
CREATE TABLE public.vee_default  PARTITION OF public.video_engagement_events DEFAULT;
CREATE TABLE public.vee_2025_02  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE public.vee_2025_03  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE public.vee_2025_04  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE public.vee_2025_05  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE public.vee_2025_06  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE public.vee_2025_07  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE public.vee_2025_08  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE public.vee_2025_09  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE public.vee_2025_10  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE public.vee_2025_11  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE public.vee_2025_12  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE public.vee_2026_01  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE public.vee_2026_02  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE public.vee_2026_03  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE public.vee_2026_04  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE public.vee_2026_05  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE public.vee_2026_06  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE public.vee_2026_07  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE public.vee_2026_08  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE public.vee_2026_09  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE public.vee_2026_10  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE public.vee_2026_11  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE public.vee_2026_12  PARTITION OF public.video_engagement_events FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

CREATE INDEX idx_vee_video        ON public.video_engagement_events(video_id);
CREATE INDEX idx_vee_user         ON public.video_engagement_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_vee_created      ON public.video_engagement_events(created_at DESC);
CREATE INDEX idx_vee_video_created ON public.video_engagement_events(video_id, created_at DESC);

ALTER TABLE public.video_engagement_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Auth insert engagement"     ON public.video_engagement_events FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users view own engagement"  ON public.video_engagement_events FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Creators view video stats"  ON public.video_engagement_events FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.creator_videos WHERE id = video_id AND creator_id = auth.uid())
);
CREATE POLICY "Admins view all engagement" ON public.video_engagement_events FOR SELECT USING (public.is_admin_or_reviewer());

-- ── Video Reactions ───────────────────────────────────────────────────────────

CREATE TABLE public.video_reactions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id      UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL CHECK (reaction_type IN ('heart', 'laugh', 'sad', 'angry', 'wow')),
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(video_id, user_id)
);

CREATE INDEX idx_vr_user ON public.video_reactions(user_id);

ALTER TABLE public.video_reactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read reactions"     ON public.video_reactions FOR SELECT USING (true);
CREATE POLICY "Users react"               ON public.video_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own reactions" ON public.video_reactions FOR UPDATE
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users unreact"             ON public.video_reactions FOR DELETE USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_reaction_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.reaction_type = 'heart' THEN
    UPDATE public.creator_videos SET like_count = like_count + 1 WHERE id = NEW.video_id;
  ELSIF TG_OP = 'DELETE' AND OLD.reaction_type = 'heart' THEN
    UPDATE public.creator_videos SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.video_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_reaction_change
  AFTER INSERT OR DELETE ON public.video_reactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_reaction_count();

-- ── Video Comments ────────────────────────────────────────────────────────────

CREATE TABLE public.video_comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id   UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  author_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content    TEXT NOT NULL,
  parent_id  UUID REFERENCES public.video_comments(id) ON DELETE CASCADE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_vc_video_created ON public.video_comments(video_id, created_at DESC);
CREATE INDEX idx_vc_parent        ON public.video_comments(parent_id) WHERE parent_id IS NOT NULL;

CREATE TRIGGER handle_vc_updated_at
  BEFORE UPDATE ON public.video_comments FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

ALTER TABLE public.video_comments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read video comments" ON public.video_comments FOR SELECT USING (deleted_at IS NULL);
CREATE POLICY "Users post comments"        ON public.video_comments FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users delete own comments"  ON public.video_comments FOR DELETE USING (auth.uid() = author_id);

CREATE OR REPLACE FUNCTION public.handle_video_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.creator_videos SET comment_count = comment_count + 1 WHERE id = NEW.video_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.creator_videos SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.video_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_video_comment_change
  AFTER INSERT OR DELETE ON public.video_comments
  FOR EACH ROW EXECUTE FUNCTION public.handle_video_comment_count();





-- Drop ALL known overloads of get_edge_feed to avoid signature conflicts
DROP FUNCTION IF EXISTS public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[]);
DROP FUNCTION IF EXISTS public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]);

CREATE OR REPLACE FUNCTION public.get_edge_feed(
  p_user_id             UUID,
  p_limit               INT          DEFAULT 15,
  p_cursor_rank         INT          DEFAULT 0,
  p_cursor_id           UUID         DEFAULT NULL,
  p_session_seed        TEXT         DEFAULT 'default',
  p_seen_ids            UUID[]       DEFAULT '{}',
  p_recent_genres       TEXT[]       DEFAULT '{}',
  p_local_blocked_ids   UUID[]       DEFAULT '{}'
)
RETURNS TABLE (
  id                    UUID,
  creator_id            UUID,
  title                 TEXT,
  description           TEXT,
  video_url             TEXT,
  thumbnail_url         TEXT,
  duration_seconds      INT,
  duration_ms           INT,
  view_count            INT,
  like_count            INT,
  comment_count         INT,
  share_count           INT,
  status                TEXT,
  category              TEXT,
  avg_completion_pct    NUMERIC,
  engagement_score      NUMERIC,
  mux_playback_id       TEXT,
  mux_status            TEXT,
  created_at            TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ,
  deleted_at            TIMESTAMPTZ,
  creator_username      TEXT,
  creator_avatar_url    TEXT,
  tmdb_id               INT,
  tmdb_title            TEXT,
  tmdb_type             TEXT,
  liked_by_current_user BOOLEAN,
  rank_position         INT
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
    v.tmdb_type,
    -- Liked state for current user
    EXISTS (
      SELECT 1 FROM public.video_reactions vr
       WHERE vr.video_id = v.id
         AND vr.user_id = p_user_id
         AND vr.reaction_type = 'heart'
    ) AS liked_by_current_user,
    -- Return computed rank_position so the frontend can build the next cursor accurately
    (
      fr.rank_position + (
        CASE
          WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
          WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
          ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
        END
      )
      + (CASE WHEN v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND v.tags[1]::text = ANY(p_recent_genres) THEN 0 ELSE 100000 END)
      + (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 50000 END)
    ) AS rank_position

  FROM public.feed_rankings fr
  INNER JOIN public.creator_videos v ON v.id = fr.video_id
  LEFT JOIN public.profiles p ON p.id = v.creator_id

  WHERE
    fr.category = 'for_you'

    -- Index-friendly rough boundary to prevent full table scans when cursor is deep
    -- Adjusted by 150050 to account for the max possible penalty (100k + 50k + 50)
    AND fr.rank_position >= GREATEST(0, p_cursor_rank - 150050)

    -- Exact Cursor pagination using the computed jittered and penalized rank
    AND (
      p_cursor_rank = 0
      OR (
        fr.rank_position + (
          CASE
            WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
            WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
            ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
          END
        )
        + (CASE WHEN v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND v.tags[1]::text = ANY(p_recent_genres) THEN 0 ELSE 100000 END)
        + (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 50000 END)
      ) > p_cursor_rank
      OR (
        (
          fr.rank_position + (
            CASE
              WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
              WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
              ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
            END
          )
          + (CASE WHEN v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND v.tags[1]::text = ANY(p_recent_genres) THEN 0 ELSE 100000 END)
          + (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 50000 END)
        ) = p_cursor_rank AND v.id > p_cursor_id
      )
    )

    -- Backend seen-video dedup
    AND (
      p_seen_ids IS NULL
      OR array_length(p_seen_ids, 1) IS NULL
      OR v.id != ALL(p_seen_ids)
    )

    -- Standard safety filters
    AND v.deleted_at IS NULL
    AND COALESCE(p.is_banned, false) = false
    AND (COALESCE(p.is_shadowbanned, false) = false OR v.creator_id = p_user_id)

    -- Block compliance
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = p_user_id AND ub.blocked_id = v.creator_id)
          OR (ub.blocker_id = v.creator_id AND ub.blocked_id = p_user_id)
    )

    -- Local Block compliance (Optimistic UI filtering sent from client)
    AND (
      p_local_blocked_ids IS NULL 
      OR array_length(p_local_blocked_ids, 1) IS NULL 
      OR v.creator_id != ALL(p_local_blocked_ids)
    )

    -- Status filter
    AND (
      v.status = 'approved'
      OR (v.mux_status = 'ready' AND v.status NOT IN ('rejected', 'removed', 'disabled'))
    )

    AND (v.suppress_until IS NULL OR v.suppress_until < now())

  ORDER BY
    (
      fr.rank_position + (
        CASE
          WHEN fr.rank_position <= 50 THEN abs(hashtext(v.id::text || p_session_seed)) % 5
          WHEN fr.rank_position <= 200 THEN abs(hashtext(v.id::text || p_session_seed)) % 20
          ELSE abs(hashtext(v.id::text || p_session_seed)) % 50
        END
      )
      + (CASE WHEN v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND v.tags[1]::text = ANY(p_recent_genres) THEN 0 ELSE 100000 END)
      + (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 50000 END)
    ) ASC,
    v.id ASC

  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Secure the RPC
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) FROM anon;

GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, INT, UUID, TEXT, UUID[], TEXT[], UUID[]) TO postgres;




-- ── Feed Rankings ─────────────────────────────────────────────────────────────

CREATE TABLE public.feed_rankings (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_id      UUID NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  category      TEXT DEFAULT 'for_you' CHECK (category IN ('for_you', 'following', 'trending')),
  rank_position INT NOT NULL,
  computed_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE (video_id, category)
);

-- Covering index — index-only scan for feed queries
CREATE INDEX idx_fr_cat_rank_vid ON public.feed_rankings(category, rank_position) INCLUDE (video_id, computed_at);
ALTER TABLE public.feed_rankings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read rankings"  ON public.feed_rankings FOR SELECT USING (true);
CREATE POLICY "Admins manage rankings" ON public.feed_rankings FOR ALL USING (public.is_admin_or_reviewer());



