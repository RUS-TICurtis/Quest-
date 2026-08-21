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
