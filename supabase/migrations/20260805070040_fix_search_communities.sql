-- Fix search_communities to include media_type

DROP FUNCTION IF EXISTS public.search_communities(text, int, int);

CREATE OR REPLACE FUNCTION public.search_communities(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id BIGINT,
  show_id INT,
  title TEXT,
  poster_path TEXT,
  member_count INT,
  media_type TEXT,
  rank REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.show_id, c.title, c.poster_path, c.member_count, c.media_type,
    (ts_rank(c.search_vector, websearch_to_tsquery('english', p_query)) * (1.0 + LN(GREATEST(c.member_count, 1))))::REAL AS rank
  FROM public.communities c
  WHERE c.search_vector @@ websearch_to_tsquery('english', p_query)
    AND c.status = 'active'
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
