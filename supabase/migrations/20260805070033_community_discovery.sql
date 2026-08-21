-- ============================================================================
-- COMMUNITY DISCOVERY SYSTEM
-- Phase 1: Schema additions + RPCs
-- Adds trending scores, activity counters, interaction tracking,
-- and read-optimised ranking RPCs for the discovery feed.
-- ============================================================================

-- ── 1. Trending columns on communities ───────────────────────────────────────

ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS trending_score    DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS posts_24h         INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS comments_24h      INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS active_users_24h  INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS shares_24h        INTEGER DEFAULT 0;

-- Hot-path index: fetching trending communities is O(log n) on this
CREATE INDEX IF NOT EXISTS idx_communities_trending
  ON public.communities(trending_score DESC)
  WHERE status = 'active';

-- ── 2. Trending + engagement columns on community_posts ──────────────────────

ALTER TABLE public.community_posts
  ADD COLUMN IF NOT EXISTS trending_score       DOUBLE PRECISION DEFAULT 0,
  ADD COLUMN IF NOT EXISTS shares_count         INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS engagement_velocity  DOUBLE PRECISION DEFAULT 0;

-- Trending feed index
CREATE INDEX IF NOT EXISTS idx_posts_trending
  ON public.community_posts(trending_score DESC)
  WHERE deleted_at IS NULL AND is_hidden = false;

-- Most-liked / popular feed index (composite covers both sort keys)
CREATE INDEX IF NOT EXISTS idx_posts_popular
  ON public.community_posts(upvotes DESC, comment_count DESC)
  WHERE deleted_at IS NULL AND is_hidden = false;

-- Latest feed index (already exists as idx_posts_community_created but we add
-- a global one for cross-community latest discovery)
CREATE INDEX IF NOT EXISTS idx_posts_global_latest
  ON public.community_posts(created_at DESC)
  WHERE deleted_at IS NULL AND is_hidden = false;

-- ── 3. user_community_interactions ───────────────────────────────────────────
-- Lightweight interaction log per (user, community) pair.
-- Powers "Communities For You" MVP + future ML collaborative filtering.

CREATE TABLE IF NOT EXISTS public.user_community_interactions (
  user_id             UUID   NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  community_id        BIGINT NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  likes_count         INTEGER DEFAULT 0,
  comments_count      INTEGER DEFAULT 0,
  posts_count         INTEGER DEFAULT 0,
  view_time_seconds   INTEGER DEFAULT 0,
  last_interaction_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, community_id)
);

CREATE INDEX IF NOT EXISTS idx_uci_user_recent
  ON public.user_community_interactions(user_id, last_interaction_at DESC);

ALTER TABLE public.user_community_interactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own community interactions"
  ON public.user_community_interactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users upsert own community interactions"
  ON public.user_community_interactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own community interactions"
  ON public.user_community_interactions FOR UPDATE USING (auth.uid() = user_id);

-- ── 4. Atomic RPC: increment_post_shares ─────────────────────────────────────
-- Called by Flutter after the OS share sheet completes.

CREATE OR REPLACE FUNCTION public.increment_post_shares(p_post_id UUID)
RETURNS void AS $$
  UPDATE public.community_posts
  SET shares_count = shares_count + 1,
      last_activity_at = now()
  WHERE id = p_post_id
    AND deleted_at IS NULL;
$$ LANGUAGE sql SECURITY DEFINER;

-- ── 5. RPC: track_community_interaction ──────────────────────────────────────
-- Upserts interaction counters. Called when user opens a community detail page.

CREATE OR REPLACE FUNCTION public.track_community_interaction(
  p_community_id      BIGINT,
  p_view_time_seconds INTEGER DEFAULT 0,
  p_liked             BOOLEAN DEFAULT false,
  p_commented         BOOLEAN DEFAULT false,
  p_posted            BOOLEAN DEFAULT false
) RETURNS void AS $$
DECLARE v_uid UUID := auth.uid();
BEGIN
  INSERT INTO public.user_community_interactions (
    user_id, community_id, likes_count, comments_count, posts_count,
    view_time_seconds, last_interaction_at
  ) VALUES (
    v_uid, p_community_id,
    (p_liked::int), (p_commented::int), (p_posted::int),
    p_view_time_seconds, now()
  )
  ON CONFLICT (user_id, community_id) DO UPDATE SET
    likes_count         = user_community_interactions.likes_count + (p_liked::int),
    comments_count      = user_community_interactions.comments_count + (p_commented::int),
    posts_count         = user_community_interactions.posts_count + (p_posted::int),
    view_time_seconds   = user_community_interactions.view_time_seconds + p_view_time_seconds,
    last_interaction_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 6. RPC: get_trending_communities ─────────────────────────────────────────
-- Returns communities ordered by pre-computed trending_score.
-- Score is written by the recalculate-community-trending Edge Function every 5 min.

CREATE OR REPLACE FUNCTION public.get_trending_communities(
  p_limit  INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id               BIGINT,
  show_id          INT,
  title            TEXT,
  poster_path      TEXT,
  media_type       TEXT,
  member_count     INT,
  post_count       INT,
  trending_score   DOUBLE PRECISION,
  posts_24h        INT,
  active_users_24h INT,
  last_activity_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.show_id, c.title, c.poster_path, c.media_type,
    c.member_count, c.post_count, c.trending_score,
    c.posts_24h, c.active_users_24h, c.last_activity_at
  FROM public.communities c
  WHERE c.status = 'active'
    AND c.trending_score > 0
  ORDER BY c.trending_score DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;

-- ── 7. RPC: get_trending_posts ────────────────────────────────────────────────
-- Returns posts ordered by pre-computed trending_score (written every 5 min).
-- Optional community_id filter for in-community trending view.

CREATE OR REPLACE FUNCTION public.get_trending_posts(
  p_community_id BIGINT DEFAULT NULL,
  p_limit        INT    DEFAULT 30,
  p_offset       INT    DEFAULT 0
)
RETURNS TABLE (
  id             UUID,
  community_id   BIGINT,
  show_id        INT,
  author_id      UUID,
  content        TEXT,
  media_urls     TEXT[],
  upvotes        INT,
  downvotes      INT,
  score          INT,
  comment_count  INT,
  shares_count   INT,
  trending_score DOUBLE PRECISION,
  created_at     TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id, cp.community_id, cp.show_id, cp.author_id,
    cp.content, cp.media_urls, cp.upvotes, cp.downvotes,
    cp.score, cp.comment_count, cp.shares_count,
    cp.trending_score, cp.created_at
  FROM public.community_posts cp
  WHERE cp.deleted_at IS NULL
    AND cp.is_hidden = false
    AND (p_community_id IS NULL OR cp.community_id = p_community_id)
    AND cp.trending_score > 0
  ORDER BY cp.trending_score DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;

-- ── 8. RPC: get_popular_posts ─────────────────────────────────────────────────
-- Returns most-liked posts within a time window.
-- popular_score = upvotes*1 + comments*2 + shares*3
-- (Comments and shares signal deeper engagement than passive upvotes)

CREATE OR REPLACE FUNCTION public.get_popular_posts(
  p_community_id BIGINT DEFAULT NULL,
  p_window       TEXT   DEFAULT '24h',  -- '24h' | '7d' | 'all'
  p_limit        INT    DEFAULT 30,
  p_offset       INT    DEFAULT 0
)
RETURNS TABLE (
  id            UUID,
  community_id  BIGINT,
  show_id       INT,
  author_id     UUID,
  content       TEXT,
  media_urls    TEXT[],
  upvotes       INT,
  comment_count INT,
  shares_count  INT,
  popular_score BIGINT,
  created_at    TIMESTAMPTZ
) AS $$
DECLARE
  v_cutoff TIMESTAMPTZ;
BEGIN
  v_cutoff := CASE p_window
    WHEN '24h' THEN now() - INTERVAL '24 hours'
    WHEN '7d'  THEN now() - INTERVAL '7 days'
    ELSE        '1970-01-01'::TIMESTAMPTZ
  END;

  RETURN QUERY
  SELECT
    cp.id, cp.community_id, cp.show_id, cp.author_id,
    cp.content, cp.media_urls, cp.upvotes, cp.comment_count,
    cp.shares_count,
    (cp.upvotes * 1 + cp.comment_count * 2 + cp.shares_count * 3)::BIGINT AS popular_score,
    cp.created_at
  FROM public.community_posts cp
  WHERE cp.deleted_at IS NULL
    AND cp.is_hidden = false
    AND cp.created_at >= v_cutoff
    AND (p_community_id IS NULL OR cp.community_id = p_community_id)
  ORDER BY popular_score DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;

-- ── 9. RPC: get_latest_posts ──────────────────────────────────────────────────
-- Pure chronological feed. No algorithm, no ranking.
-- Relies on idx_posts_global_latest for fast reads.

CREATE OR REPLACE FUNCTION public.get_latest_posts(
  p_community_id BIGINT DEFAULT NULL,
  p_limit        INT    DEFAULT 30,
  p_offset       INT    DEFAULT 0
)
RETURNS TABLE (
  id            UUID,
  community_id  BIGINT,
  show_id       INT,
  author_id     UUID,
  content       TEXT,
  media_urls    TEXT[],
  upvotes       INT,
  comment_count INT,
  created_at    TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id, cp.community_id, cp.show_id, cp.author_id,
    cp.content, cp.media_urls, cp.upvotes, cp.comment_count, cp.created_at
  FROM public.community_posts cp
  WHERE cp.deleted_at IS NULL
    AND cp.is_hidden = false
    AND (p_community_id IS NULL OR cp.community_id = p_community_id)
  ORDER BY cp.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;

-- ── 10. RPC: get_communities_for_you ─────────────────────────────────────────
-- MVP recommendation: genre-overlap with user's library + trending_score.
-- Future: replace the genre sub-select with pgvector similarity scoring.

CREATE OR REPLACE FUNCTION public.get_communities_for_you(
  p_limit  INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  id                    BIGINT,
  show_id               INT,
  title                 TEXT,
  poster_path           TEXT,
  media_type            TEXT,
  member_count          INT,
  trending_score        DOUBLE PRECISION,
  recommendation_reason TEXT
) AS $$
DECLARE
  v_uid               UUID := auth.uid();
  v_preferred_genres  INT[];
BEGIN
  -- Collect genre_ids from titles the user has added to their library
  SELECT ARRAY_AGG(DISTINCT genre_id)
  INTO v_preferred_genres
  FROM (
    SELECT UNNEST(t.genre_ids) AS genre_id
    FROM public.user_titles ut
    JOIN public.titles t ON t.tmdb_id::TEXT = ut.title_id
    WHERE ut.user_id = v_uid
      AND ut.status IN ('watched', 'watching', 'want_to_watch')
    LIMIT 100
  ) sub;

  -- If user has no library history, fall back to pure trending
  IF v_preferred_genres IS NULL OR array_length(v_preferred_genres, 1) = 0 THEN
    RETURN QUERY
    SELECT
      c.id, c.show_id, c.title, c.poster_path, c.media_type,
      c.member_count, c.trending_score,
      'Trending now'::TEXT AS recommendation_reason
    FROM public.communities c
    WHERE c.status = 'active'
      AND NOT EXISTS (
        SELECT 1 FROM public.community_members cm
        WHERE cm.community_id = c.id AND cm.user_id = v_uid
      )
    ORDER BY c.trending_score DESC, c.member_count DESC
    LIMIT p_limit OFFSET p_offset;
    RETURN;
  END IF;

  -- Genre-matched communities the user hasn't joined, ranked by trending_score
  RETURN QUERY
  SELECT DISTINCT
    c.id, c.show_id, c.title, c.poster_path, c.media_type,
    c.member_count, c.trending_score,
    'Based on your taste'::TEXT AS recommendation_reason
  FROM public.communities c
  JOIN public.titles t ON t.tmdb_id = c.show_id
  WHERE c.status = 'active'
    AND NOT EXISTS (
      SELECT 1 FROM public.community_members cm
      WHERE cm.community_id = c.id AND cm.user_id = v_uid
    )
    AND t.genre_ids && v_preferred_genres  -- array overlap operator
  ORDER BY c.trending_score DESC, c.member_count DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
