-- ============================================================================
-- FIX: get_trending_posts still filtered by trending_score > 0
-- Same issue as communities: posts cron may not have run yet, so all scores
-- are 0 and "Popular Discussions" showed nothing.
-- Also re-add GRANT EXECUTE in case DROP+CREATE stripped permissions.
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_trending_posts(BIGINT, INT, INT);

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
    COALESCE(p.username, 'Anonymous') AS author_name,
    p.avatar_url                       AS author_avatar,
    cp.content,
    cp.media_urls,
    cp.upvotes,
    cp.downvotes,
    cp.score,
    cp.comment_count,
    cp.shares_count,
    cp.trending_score,
    cp.is_spoiler,
    c.title                            AS show_title,
    cp.created_at
  FROM public.community_posts cp
  LEFT JOIN public.profiles p    ON p.id  = cp.author_id
  LEFT JOIN public.communities c ON c.id  = cp.community_id
  WHERE cp.deleted_at IS NULL
    AND cp.is_hidden = false
    AND (p_community_id IS NULL OR cp.community_id = p_community_id)
  -- Removed: AND cp.trending_score > 0
  -- Posts with 0 score (cron not yet run) now surface ordered by
  -- trending_score DESC first, then recency for unscored posts.
  ORDER BY cp.trending_score DESC, cp.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER STABLE;

-- Re-grant execute in case DROP+CREATE stripped role permissions
GRANT EXECUTE ON FUNCTION public.get_trending_posts(BIGINT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_popular_posts(BIGINT, TEXT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_latest_posts(BIGINT, INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_trending_communities(INT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_communities_for_you(INT, INT) TO authenticated;
