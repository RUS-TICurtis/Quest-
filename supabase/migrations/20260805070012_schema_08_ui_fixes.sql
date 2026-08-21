-- ============================================================================
-- SCHEMA GROUP 8: UI Regression Fixes
-- favorite_communities, favorite_posts, daily_trending
-- ============================================================================

-- ── Favorite Communities ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.favorite_communities (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  show_id INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, show_id)
);

CREATE INDEX IF NOT EXISTS idx_fav_comm_user ON public.favorite_communities(user_id);

ALTER TABLE public.favorite_communities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage favorite communities" ON public.favorite_communities;
CREATE POLICY "Users manage favorite communities" ON public.favorite_communities
  FOR ALL USING (auth.uid() = user_id);

-- ── Favorite Posts ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.favorite_posts (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_fav_post_user ON public.favorite_posts(user_id);

ALTER TABLE public.favorite_posts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage favorite posts" ON public.favorite_posts;
CREATE POLICY "Users manage favorite posts" ON public.favorite_posts
  FOR ALL USING (auth.uid() = user_id);

-- ── Daily Trending ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.daily_trending (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE UNIQUE NOT NULL,
  movies JSONB NOT NULL DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_dt_date ON public.daily_trending(date);

ALTER TABLE public.daily_trending ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read daily trending" ON public.daily_trending;
CREATE POLICY "Public read daily trending" ON public.daily_trending
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "Service role manages daily trending" ON public.daily_trending;
CREATE POLICY "Service role manages daily trending" ON public.daily_trending
  FOR ALL USING (auth.role() = 'service_role' OR current_setting('role') = 'service_role' OR public.is_admin_or_reviewer());

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS handle_daily_trending_updated_at ON public.daily_trending;
CREATE TRIGGER handle_daily_trending_updated_at
  BEFORE UPDATE ON public.daily_trending FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);
