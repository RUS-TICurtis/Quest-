-- ============================================================================
-- SCHEMA UPGRADE: UGC Moderation & EULA/App Store Compliance
-- 1. EULA acceptance and versioning
-- 2. Report evidence attachments
-- 3. Report rate limiting triggers
-- 4. Follow cleanup on block triggers
-- 5. Blocking-aware feed RPC rewrite
-- 6. Blocking-aware global search RPC rewrites
-- 7. High-performance index optimization
-- ============================================================================

-- ── 1. EULA Acceptance & Versioning ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.terms_versions (
  version      TEXT PRIMARY KEY,
  content      TEXT NOT NULL,
  published_at TIMESTAMPTZ DEFAULT now(),
  is_active    BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.user_terms_acceptance (
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  version     TEXT NOT NULL REFERENCES public.terms_versions(version),
  accepted_at TIMESTAMPTZ DEFAULT now(),
  ip_address  TEXT,
  user_agent  TEXT,
  PRIMARY KEY (user_id, version)
);

CREATE INDEX IF NOT EXISTS idx_user_terms_acceptance_user 
  ON public.user_terms_acceptance(user_id, accepted_at DESC);

-- Enable RLS on EULA tables
ALTER TABLE public.terms_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_terms_acceptance ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read terms" ON public.terms_versions;
CREATE POLICY "Public read terms" ON public.terms_versions FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins manage terms" ON public.terms_versions;
CREATE POLICY "Admins manage terms" ON public.terms_versions FOR ALL USING (public.is_admin_or_reviewer());

DROP POLICY IF EXISTS "Users view own acceptance" ON public.user_terms_acceptance;
CREATE POLICY "Users view own acceptance" ON public.user_terms_acceptance FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own acceptance" ON public.user_terms_acceptance;
CREATE POLICY "Users insert own acceptance" ON public.user_terms_acceptance FOR INSERT WITH CHECK (auth.uid() = user_id);

-- EULA acceptance RPC
CREATE OR REPLACE FUNCTION public.accept_user_terms(
  p_version TEXT,
  p_ip      TEXT DEFAULT NULL,
  p_ua      TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.user_terms_acceptance (user_id, version, ip_address, user_agent)
  VALUES (auth.uid(), p_version, p_ip, p_ua)
  ON CONFLICT (user_id, version) DO UPDATE SET accepted_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── 2. Report Evidence & Validation ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.report_evidence (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id  UUID NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  media_url  TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'text')),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_report_evidence_report ON public.report_evidence(report_id);

-- Enable RLS on report evidence
ALTER TABLE public.report_evidence ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users submit own evidence" ON public.report_evidence;
CREATE POLICY "Users submit own evidence" ON public.report_evidence FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.reports
       WHERE id = report_id AND reporter_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins manage evidence" ON public.report_evidence;
CREATE POLICY "Admins manage evidence" ON public.report_evidence FOR ALL USING (public.is_admin_or_reviewer());

-- ── 3. Report Rate Limiting & Abuse Prevention ───────────────────────────────

CREATE OR REPLACE FUNCTION public.check_report_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  v_report_count INT;
BEGIN
  -- Count reports made by this user in the last 60 seconds
  SELECT COUNT(*) INTO v_report_count
  FROM public.reports
  WHERE reporter_id = NEW.reporter_id
    AND created_at > now() - interval '1 minute';

  IF v_report_count >= 5 THEN
    RAISE EXCEPTION 'Rate limit exceeded: You can only submit up to 5 reports per minute.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_report_rate_limit ON public.reports;
CREATE TRIGGER trigger_report_rate_limit
  BEFORE INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.check_report_rate_limit();

-- ── 4. Follow Cleanup on Block ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.clean_follows_on_block()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM public.follows
  WHERE (follower_id = NEW.blocker_id AND following_id = NEW.blocked_id)
     OR (follower_id = NEW.blocked_id AND following_id = NEW.blocker_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_clean_follows_on_block ON public.user_blocks;
CREATE TRIGGER trigger_clean_follows_on_block
  AFTER INSERT ON public.user_blocks
  FOR EACH ROW EXECUTE FUNCTION public.clean_follows_on_block();

-- Optimized indices for checking blocking status
CREATE INDEX IF NOT EXISTS idx_user_blocks_composite ON public.user_blocks(blocker_id, blocked_id);
CREATE INDEX IF NOT EXISTS idx_user_blocks_reverse ON public.user_blocks(blocked_id, blocker_id);

-- ── 5. Blocking-Aware Feed RPC Rewrite ────────────────────────────────────────

DROP FUNCTION IF EXISTS public.get_edge_feed(UUID, INT, NUMERIC);

CREATE FUNCTION public.get_edge_feed(
  p_user_id      UUID,
  p_limit        INT,
  p_cursor_score NUMERIC
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
    -- Restrict videos from banned creators
    AND p.is_banned = false
    -- Support shadowbanning: shadowbanned creator videos only visible to themselves
    AND (p.is_shadowbanned = false OR v.creator_id = p_user_id)
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
    AND NOT EXISTS (
      SELECT 1
      FROM public.user_video_views uv
      WHERE uv.video_id = v.id
        AND uv.user_id  = p_user_id
        AND uv.created_at > now() - interval '7 days'
    )
    AND (p_cursor_score IS NULL OR v.engagement_score < p_cursor_score)
  ORDER BY v.engagement_score DESC, v.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_edge_feed(UUID, INT, NUMERIC) TO service_role;

-- ── 6. Blocking-Aware Global Search RPC Rewrites ──────────────────────────────

-- Search Users (Excluding banned and blocked accounts)
DROP FUNCTION IF EXISTS public.search_users(text, int, int);
CREATE FUNCTION public.search_users(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
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

-- Search Posts (Excluding posts by blocked users or community suspensions)
DROP FUNCTION IF EXISTS public.search_posts(text, int, int);
CREATE FUNCTION public.search_posts(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
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
    -- COMPLIANCE: Exclude posts by blocked or blocking users
    AND NOT EXISTS (
      SELECT 1 FROM public.user_blocks ub
       WHERE (ub.blocker_id = auth.uid() AND ub.blocked_id = cp.author_id)
          OR (ub.blocker_id = cp.author_id AND ub.blocked_id = auth.uid())
    )
  ORDER BY rank DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;

-- Search Creator Videos (Excluding videos by blocked creators or banned creators)
DROP FUNCTION IF EXISTS public.search_creator_videos(text, int, int);
CREATE FUNCTION public.search_creator_videos(p_query TEXT, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0)
RETURNS TABLE (
  id UUID,
  creator_id UUID,
  creator_username TEXT,
  creator_avatar_url TEXT,
  title TEXT,
  description TEXT,
  thumbnail_url TEXT,
  video_url TEXT,
  view_count INT,
  like_count INT,
  comment_count INT,
  share_count INT,
  engagement_score NUMERIC,
  mux_playback_id TEXT,
  mux_status TEXT,
  status TEXT,
  tmdb_id INT,
  tmdb_type TEXT,
  tmdb_title TEXT,
  duration_seconds INT,
  spoiler BOOLEAN,
  tags TEXT[],
  created_at TIMESTAMPTZ,
  rank REAL
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
    AND p.is_banned = false
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

-- Populate default terms version
INSERT INTO public.terms_versions (version, content, is_active)
VALUES ('1.0.0', 'Welcome to Finishd! You must comply with our Community Guidelines. We do not tolerate any abusive, harassing, toxic, or sexually explicit content. Violators will be immediately banned and their accounts terminated.', true)
ON CONFLICT (version) DO NOTHING;
