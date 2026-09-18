-- ============================================================================
-- Unified Videos, User Trust Scores, Cleanup & Global Search Migration
-- ============================================================================

-- 1. USER TRUST SCORES TABLE
CREATE TABLE IF NOT EXISTS public.user_trust_scores (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  score NUMERIC(5,2) DEFAULT 50.0,
  level TEXT DEFAULT 'Bronze',
  calculated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. CENTRAL UNIFIED VIDEOS TABLE
-- Unified table for stories, feed videos, in-chat clips, community clips, event vlogs, etc.
CREATE TABLE IF NOT EXISTS public.videos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  video_type TEXT NOT NULL DEFAULT 'feed', -- 'story', 'feed', 'chat', 'community', 'event', 'vlog'
  video_url TEXT,
  thumbnail_url TEXT,
  mux_playback_id TEXT,
  mux_asset_id TEXT,
  title TEXT,
  description TEXT,
  duration_seconds INT DEFAULT 0,
  trust_score NUMERIC(5,2) DEFAULT 50.0,
  engagement_score NUMERIC DEFAULT 0.0,
  like_count INT DEFAULT 0,
  comment_count INT DEFAULT 0,
  view_count INT DEFAULT 0,
  share_count INT DEFAULT 0,
  tags TEXT[] DEFAULT '{}',
  community_id UUID REFERENCES public.communities(id) ON DELETE SET NULL,
  event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
  quest_id UUID,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_videos_type ON public.videos(video_type);
CREATE INDEX IF NOT EXISTS idx_videos_user ON public.videos(user_id);
CREATE INDEX IF NOT EXISTS idx_videos_trust ON public.videos(trust_score DESC);
CREATE INDEX IF NOT EXISTS idx_videos_created ON public.videos(created_at DESC);

-- Enable RLS
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_trust_scores ENABLE ROW LEVEL SECURITY;

-- Permissive policies for videos
DROP POLICY IF EXISTS "Allow public read access to videos" ON public.videos;
CREATE POLICY "Allow public read access to videos" ON public.videos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert own videos" ON public.videos;
CREATE POLICY "Users can insert own videos" ON public.videos FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

DROP POLICY IF EXISTS "Users can update own videos" ON public.videos;
CREATE POLICY "Users can update own videos" ON public.videos FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own videos" ON public.videos;
CREATE POLICY "Users can delete own videos" ON public.videos FOR DELETE USING (auth.uid() = user_id);

-- Policies for user_trust_scores
DROP POLICY IF EXISTS "Allow public read access to user_trust_scores" ON public.user_trust_scores;
CREATE POLICY "Allow public read access to user_trust_scores" ON public.user_trust_scores FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can upsert own trust score" ON public.user_trust_scores;
CREATE POLICY "Users can upsert own trust score" ON public.user_trust_scores FOR ALL USING (auth.uid() = user_id);

-- 3. CLEANUP LEFTOVER & UNUSED TABLES
DROP TABLE IF EXISTS public.vee_default CASCADE;
DROP TABLE IF EXISTS public.vee_2025_02 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_03 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_04 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_05 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_06 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_07 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_08 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_09 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_10 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_11 CASCADE;
DROP TABLE IF EXISTS public.vee_2025_12 CASCADE;
DROP TABLE IF EXISTS public.user_blocks CASCADE;
DROP TABLE IF EXISTS public.user_roles CASCADE;
DROP TABLE IF EXISTS public.user_title_statuses CASCADE;

-- 4. RENAME / ALIAS creator_videos TO feed_videos IF PRESENT
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'creator_videos'
  ) THEN
    ALTER TABLE public.creator_videos RENAME TO feed_videos;
  END IF;
END $$;

-- 5. SCHEDULE 24-HOUR STORIES DELETION VIA PG_CRON IF AVAILABLE
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'cleanup_old_stories_24h',
      '0 * * * *',
      $cron$
        DELETE FROM public.videos
        WHERE video_type = 'story'
          AND created_at < NOW() - INTERVAL '24 hours';
      $cron$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Gracefully ignore if pg_cron functions are unavailable in local or staging environment
  NULL;
END $$;
