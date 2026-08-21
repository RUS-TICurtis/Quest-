-- ============================================================================
-- GLOBAL SEARCH SCHEMA & RPC FUNCTIONS
-- Implements high-performance full-text search with GIN indexes and weighted ranking
-- ============================================================================

-- ── 1. Generated Search Vectors and GIN Indexes ──────────────────────────────

-- Helper IMMUTABLE function to convert text array to string
CREATE OR REPLACE FUNCTION public.immutable_array_to_string(text[], text)
RETURNS text AS $$
  SELECT array_to_string($1, $2);
$$ LANGUAGE sql IMMUTABLE;

-- Profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(username, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(display_name, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(bio, '')), 'C')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_profiles_search_vector ON public.profiles USING GIN (search_vector);

-- Communities
ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(title, '')), 'A')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_communities_search_vector ON public.communities USING GIN (search_vector);

-- Community Posts
ALTER TABLE public.community_posts
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(content, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(public.immutable_array_to_string(hashtags, ' '), '')), 'B')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_posts_search_vector ON public.community_posts USING GIN (search_vector) WHERE deleted_at IS NULL;

-- Titles
ALTER TABLE public.titles
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(overview, '')), 'C')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_titles_search_vector ON public.titles USING GIN (search_vector);

-- Creator Videos
ALTER TABLE public.creator_videos
  ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(public.immutable_array_to_string(tags, ' '), '')), 'B') ||
    setweight(to_tsvector('english', coalesce(description, '')), 'C')
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_creator_videos_search_vector ON public.creator_videos USING GIN (search_vector) WHERE status = 'approved' AND deleted_at IS NULL;


-- ── 2. RPC Search Functions ──────────────────────────────────────────────────
-- Changed to SECURITY INVOKER so RLS policies are applied automatically

-- Search Users
CREATE OR REPLACE FUNCTION public.search_users(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  role TEXT,
  reputation_score NUMERIC,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id, p.username, p.display_name, p.avatar_url, p.bio, p.role, p.reputation_score,
    (ts_rank(p.search_vector, websearch_to_tsquery('english', p_query)) * (1.0 + (COALESCE(p.reputation_score, 0) / 1000.0)))::REAL AS rank
  FROM public.profiles p
  WHERE p.search_vector @@ websearch_to_tsquery('english', p_query)
    AND p.is_banned = false
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Search Communities
CREATE OR REPLACE FUNCTION public.search_communities(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id BIGINT,
  show_id INT,
  title TEXT,
  poster_path TEXT,
  member_count INT,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.show_id, c.title, c.poster_path, c.member_count,
    (ts_rank(c.search_vector, websearch_to_tsquery('english', p_query)) * (1.0 + LN(GREATEST(c.member_count, 1))))::REAL AS rank
  FROM public.communities c
  WHERE c.search_vector @@ websearch_to_tsquery('english', p_query)
    AND c.status = 'active'
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Search Posts
CREATE OR REPLACE FUNCTION public.search_posts(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID,
  community_id BIGINT,
  author_id UUID,
  content TEXT,
  media_urls TEXT[],
  score INT,
  comment_count INT,
  created_at TIMESTAMPTZ,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cp.id, cp.community_id, cp.author_id, cp.content, cp.media_urls, cp.score, cp.comment_count, cp.created_at,
    ((ts_rank(cp.search_vector, websearch_to_tsquery('english', p_query)) * 0.7) +
    (LN(GREATEST(COALESCE(cp.score, 0) + COALESCE(cp.comment_count, 0), 1)) * 0.2) +
    (EXP(-EXTRACT(EPOCH FROM (now() - cp.created_at))/86400.0) * 0.1))::REAL AS rank
  FROM public.community_posts cp
  WHERE cp.search_vector @@ websearch_to_tsquery('english', p_query)
    AND cp.deleted_at IS NULL
    AND cp.is_hidden = false
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Search Titles
CREATE OR REPLACE FUNCTION public.search_titles(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID,
  tmdb_id INT,
  media_type TEXT,
  title TEXT,
  overview TEXT,
  poster_url TEXT,
  release_date DATE,
  popularity NUMERIC,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id, t.tmdb_id, t.media_type, t.title, t.overview, t.poster_url, t.release_date, t.popularity,
    (ts_rank(t.search_vector, websearch_to_tsquery('english', p_query)) * (1.0 + LN(GREATEST(t.popularity, 1))))::REAL AS rank
  FROM public.titles t
  WHERE t.search_vector @@ websearch_to_tsquery('english', p_query)
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Search Creator Videos
CREATE OR REPLACE FUNCTION public.search_creator_videos(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID,
  creator_id UUID,
  title TEXT,
  description TEXT,
  thumbnail_url TEXT,
  video_url TEXT,
  view_count INT,
  like_count INT,
  created_at TIMESTAMPTZ,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cv.id, cv.creator_id, cv.title, cv.description, cv.thumbnail_url, cv.video_url, cv.view_count, cv.like_count, cv.created_at,
    ((ts_rank(cv.search_vector, websearch_to_tsquery('english', p_query)) * 0.7) +
    (LN(GREATEST(COALESCE(cv.engagement_score, 0), 1)) * 0.2) +
    (EXP(-EXTRACT(EPOCH FROM (now() - cv.created_at))/86400.0) * 0.1))::REAL AS rank
  FROM public.creator_videos cv
  WHERE cv.search_vector @@ websearch_to_tsquery('english', p_query)
    AND cv.status = 'approved'
    AND cv.deleted_at IS NULL
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;


-- ── 3. Global Unified Search RPC ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.global_search(p_query TEXT, p_limit_per_category INT DEFAULT 5)
RETURNS JSONB AS $$
DECLARE
  v_users JSONB;
  v_communities JSONB;
  v_posts JSONB;
  v_titles JSONB;
  v_videos JSONB;
  v_result JSONB;
BEGIN
  -- We fetch top N for each category using the dedicated functions

  SELECT COALESCE(jsonb_agg(row_to_json(u)), '[]'::jsonb) INTO v_users
  FROM (SELECT * FROM public.search_users(p_query, p_limit_per_category, 0)) u;

  SELECT COALESCE(jsonb_agg(row_to_json(c)), '[]'::jsonb) INTO v_communities
  FROM (SELECT * FROM public.search_communities(p_query, p_limit_per_category, 0)) c;

  SELECT COALESCE(jsonb_agg(row_to_json(p)), '[]'::jsonb) INTO v_posts
  FROM (SELECT * FROM public.search_posts(p_query, p_limit_per_category, 0)) p;

  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb) INTO v_titles
  FROM (SELECT * FROM public.search_titles(p_query, p_limit_per_category, 0)) t;

  SELECT COALESCE(jsonb_agg(row_to_json(v)), '[]'::jsonb) INTO v_videos
  FROM (SELECT * FROM public.search_creator_videos(p_query, p_limit_per_category, 0)) v;

  v_result := jsonb_build_object(
    'users', v_users,
    'communities', v_communities,
    'posts', v_posts,
    'titles', v_titles,
    'videos', v_videos
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
