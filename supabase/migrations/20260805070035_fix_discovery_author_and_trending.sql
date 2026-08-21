-- ============================================================================
-- FIX: Community Discovery — Author names + Trending communities
-- 
-- Bug 1: get_trending_communities returned nothing when trending_score = 0
--        (cold start / cron not yet run). Fixed by removing score > 0 guard.
--
-- Bug 2: get_trending_posts / get_popular_posts / get_latest_posts returned
--        author_id but NOT author_name / author_avatar, so Flutter rendered
--        every post author as "Anonymous". Fixed by joining public.profiles.
--
-- PostgreSQL requires DROP before CREATE OR REPLACE when return type changes.
-- ============================================================================

-- ── 1. get_trending_communities ───────────────────────────────────────────────
-- Now returns communities even when trending_score = 0 (newly seeded app).

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
  -- Removed: AND c.trending_score > 0
  -- Now returns all active communities so UI works before cron has run.
  ORDER BY c.trending_score DESC, c.member_count DESC, c.last_activity_at DESC NULLS LAST
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;

-- Drop old versions before recreating with new return columns
DROP FUNCTION IF EXISTS public.get_trending_posts(BIGINT, INT, INT);
DROP FUNCTION IF EXISTS public.get_popular_posts(BIGINT, TEXT, INT, INT);
DROP FUNCTION IF EXISTS public.get_latest_posts(BIGINT, INT, INT);

-- ── 2. get_trending_posts (with author hydration) ─────────────────────────────

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
  author_name    TEXT,
  author_avatar  TEXT,
  content        TEXT,
  media_urls     TEXT[],
  upvotes        INT,
  downvotes      INT,
  score          INT,
  comment_count  INT,
  shares_count   INT,
  trending_score DOUBLE PRECISION,
  is_spoiler     BOOLEAN,
  show_title     TEXT,
  created_at     TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id,
    cp.community_id,
    cp.show_id,
    cp.author_id,
    COALESCE(p.username, 'Anonymous')   AS author_name,
    p.avatar_url                         AS author_avatar,
    cp.content,
    cp.media_urls,
    cp.upvotes,
    cp.downvotes,
    cp.score,
    cp.comment_count,
    cp.shares_count,
    cp.trending_score,
    cp.is_spoiler,
    c.title                              AS show_title,
    cp.created_at
  FROM public.community_posts cp
  LEFT JOIN public.profiles p   ON p.id  = cp.author_id
  LEFT JOIN public.communities c ON c.id = cp.community_id
  WHERE cp.deleted_at IS NULL
    AND cp.is_hidden = false
    AND (p_community_id IS NULL OR cp.community_id = p_community_id)
    AND cp.trending_score > 0
  ORDER BY cp.trending_score DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;


-- ── 3. get_popular_posts (with author hydration) ──────────────────────────────

CREATE OR REPLACE FUNCTION public.get_popular_posts(
  p_community_id BIGINT DEFAULT NULL,
  p_window       TEXT   DEFAULT '24h',
  p_limit        INT    DEFAULT 30,
  p_offset       INT    DEFAULT 0
)
RETURNS TABLE (
  id            UUID,
  community_id  BIGINT,
  show_id       INT,
  author_id     UUID,
  author_name   TEXT,
  author_avatar TEXT,
  content       TEXT,
  media_urls    TEXT[],
  upvotes       INT,
  downvotes     INT,
  score         INT,
  comment_count INT,
  shares_count  INT,
  popular_score BIGINT,
  is_spoiler    BOOLEAN,
  show_title    TEXT,
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
    cp.id,
    cp.community_id,
    cp.show_id,
    cp.author_id,
    COALESCE(p.username, 'Anonymous')   AS author_name,
    p.avatar_url                         AS author_avatar,
    cp.content,
    cp.media_urls,
    cp.upvotes,
    cp.downvotes,
    cp.score,
    cp.comment_count,
    cp.shares_count,
    (cp.upvotes * 1 + cp.comment_count * 2 + cp.shares_count * 3)::BIGINT AS popular_score,
    cp.is_spoiler,
    c.title                              AS show_title,
    cp.created_at
  FROM public.community_posts cp
  LEFT JOIN public.profiles p    ON p.id  = cp.author_id
  LEFT JOIN public.communities c ON c.id = cp.community_id
  WHERE cp.deleted_at IS NULL
    AND cp.is_hidden = false
    AND cp.created_at >= v_cutoff
    AND (p_community_id IS NULL OR cp.community_id = p_community_id)
  ORDER BY popular_score DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;


-- ── 4. get_latest_posts (with author hydration) ───────────────────────────────

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
  author_name   TEXT,
  author_avatar TEXT,
  content       TEXT,
  media_urls    TEXT[],
  upvotes       INT,
  downvotes     INT,
  score         INT,
  comment_count INT,
  is_spoiler    BOOLEAN,
  show_title    TEXT,
  created_at    TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id,
    cp.community_id,
    cp.show_id,
    cp.author_id,
    COALESCE(p.username, 'Anonymous')   AS author_name,
    p.avatar_url                         AS author_avatar,
    cp.content,
    cp.media_urls,
    cp.upvotes,
    cp.downvotes,
    cp.score,
    cp.comment_count,
    cp.is_spoiler,
    c.title                              AS show_title,
    cp.created_at
  FROM public.community_posts cp
  LEFT JOIN public.profiles p    ON p.id  = cp.author_id
  LEFT JOIN public.communities c ON c.id = cp.community_id
  WHERE cp.deleted_at IS NULL
    AND cp.is_hidden = false
    AND (p_community_id IS NULL OR cp.community_id = p_community_id)
  ORDER BY cp.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;
