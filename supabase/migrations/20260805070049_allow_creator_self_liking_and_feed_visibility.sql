-- Migration to allow creator self-liking in feed visibility and handle nullable columns robustly.

-- Safe Drops to avoid return type mismatch errors (SQLSTATE 42P13)
DROP FUNCTION IF EXISTS public.get_edge_feed(UUID, INT, INT, TEXT, TEXT[]);
DROP FUNCTION IF EXISTS public.search_creator_videos(TEXT, INT, INT);
DROP FUNCTION IF EXISTS public.search_users(TEXT, INT, INT);

-- Update get_edge_feed to avoid self-watched demotions and protect against nullable profile columns
CREATE OR REPLACE FUNCTION public.get_edge_feed(
  p_user_id        UUID,
  p_limit          INT,
  p_offset         INT,
  p_seed           TEXT,
  p_recent_genres  TEXT[] DEFAULT '{}'
)
RETURNS TABLE (
  id                 UUID,
  creator_id         UUID,
  title              TEXT,
  description        TEXT,
  video_url          TEXT,
  thumbnail_url      TEXT,
  duration_seconds   INT,
  duration_ms        INT,
  view_count         INT,
  like_count         INT,
  comment_count      INT,
  share_count        INT,
  status             TEXT,
  category           TEXT,
  avg_completion_pct NUMERIC,
  engagement_score   NUMERIC,
  mux_playback_id    TEXT,
  mux_status         TEXT,
  created_at         TIMESTAMPTZ,
  updated_at         TIMESTAMPTZ,
  deleted_at         TIMESTAMPTZ,
  creator_username   TEXT,
  creator_avatar_url TEXT,
  tmdb_id            INT,
  tmdb_title         TEXT,
  tmdb_type          TEXT
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
    v.tmdb_type
  FROM public.creator_videos v
  LEFT JOIN public.profiles p ON p.id = v.creator_id
  WHERE
    v.deleted_at IS NULL
    -- Restrict videos from banned creators (robust NULL handling)
    AND COALESCE(p.is_banned, false) = false
    -- Support shadowbanning: shadowbanned creator videos only visible to themselves (robust NULL handling)
    AND (COALESCE(p.is_shadowbanned, false) = false OR v.creator_id = p_user_id)
    -- COMPLIANCE: Exclude videos where creator is blocked by viewer or viewer is blocked by creator
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = p_user_id AND ub.blocked_id = v.creator_id)
          OR (ub.blocker_id = v.creator_id AND ub.blocked_id = p_user_id)
    )
    AND (
      v.status = 'approved'
      OR (v.mux_status = 'ready' AND v.status NOT IN ('rejected', 'removed'))
    )
    AND (v.suppress_until IS NULL OR v.suppress_until < now())
  ORDER BY 
    -- Watched videos are pushed to the end of the feed, EXCEPT for the creator's own videos (0 first, 1 last)
    (CASE WHEN EXISTS (
      SELECT 1 FROM public.user_video_views uv
      WHERE uv.video_id = v.id AND uv.user_id = p_user_id
    ) AND v.creator_id != p_user_id THEN 1 ELSE 0 END) ASC,
    -- Prioritize modern HLS-ready videos over slow legacy Storage URLs
    (CASE WHEN v.mux_playback_id IS NOT NULL AND v.mux_status = 'ready' THEN 0 ELSE 1 END) ASC,
    -- Then rank by engagement, randomized seed hashing, log age decay, and genre boosts
    (
      COALESCE(v.engagement_score, 0.0) * 
      (0.8 + 0.4 * (abs(hashtext(v.id::text || p_seed))::numeric / 2147483647.0)) * 
      -- Freshness boost: log-decay of video age in days
      COALESCE(1.5 / (1.0 + LN(1.0 + EXTRACT(EPOCH FROM (now() - v.created_at))/86400.0)), 1.0) *
      -- AI Personalization Genre Boost (+40% boost if in user's recent genres)
      CASE WHEN (
        v.tags IS NOT NULL AND array_length(v.tags, 1) > 0 AND 
        v.tags[1]::text = ANY(p_recent_genres)
      ) THEN 1.4 ELSE 1.0 END
    ) DESC,
    v.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update search_creator_videos to be robust against NULL bans and return correct metadata columns
CREATE OR REPLACE FUNCTION public.search_creator_videos(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id                 UUID,
  creator_id         UUID,
  creator_username   TEXT,
  creator_avatar_url TEXT,
  title              TEXT,
  description        TEXT,
  thumbnail_url      TEXT,
  video_url          TEXT,
  view_count         INT,
  like_count         INT,
  comment_count      INT,
  share_count        INT,
  engagement_score   NUMERIC,
  mux_playback_id    TEXT,
  mux_status         TEXT,
  status             TEXT,
  tmdb_id            INT,
  tmdb_type          TEXT,
  tmdb_title         TEXT,
  duration_seconds   INT,
  spoiler            BOOLEAN,
  tags               TEXT[],
  created_at         TIMESTAMPTZ,
  rank               REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    cv.id,
    cv.creator_id,
    p.username AS creator_username,
    p.avatar_url AS creator_avatar_url,
    cv.title,
    cv.description,
    cv.thumbnail_url,
    cv.video_url,
    cv.view_count,
    cv.like_count,
    cv.comment_count,
    cv.share_count,
    cv.engagement_score,
    cv.mux_playback_id,
    cv.mux_status,
    cv.status,
    cv.tmdb_id,
    cv.tmdb_type,
    cv.tmdb_title,
    cv.duration_seconds,
    cv.spoiler,
    cv.tags,
    cv.created_at,
    ((ts_rank(cv.search_vector, websearch_to_tsquery('english', p_query)) * 0.7) +
    (LN(GREATEST(COALESCE(cv.engagement_score, 0), 1)) * 0.2) +
    (EXP(-EXTRACT(EPOCH FROM (now() - cv.created_at))/86400.0) * 0.1))::REAL AS rank
  FROM public.creator_videos cv
  LEFT JOIN public.profiles p ON p.id = cv.creator_id
  WHERE cv.search_vector @@ websearch_to_tsquery('english', p_query)
    AND cv.status = 'approved'
    AND cv.deleted_at IS NULL
    AND COALESCE(p.is_banned, false) = false
    -- COMPLIANCE: Exclude videos from blocked or blocking creators
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = auth.uid() AND ub.blocked_id = cv.creator_id)
          OR (ub.blocker_id = cv.creator_id AND ub.blocked_id = auth.uid())
    )
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Update search_users to be robust against NULL bans
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
    AND COALESCE(p.is_banned, false) = false
    -- COMPLIANCE: Exclude blocked/blocker profiles
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = auth.uid() AND ub.blocked_id = p.id)
          OR (ub.blocker_id = p.id AND ub.blocked_id = auth.uid())
    )
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
