-- ============================================================================
-- SCHEMA GROUP 7: Infrastructure
-- Realtime publications, storage buckets, partition auto-maintenance,
-- pg_cron job registration, TTL cleanup
-- ============================================================================

-- ── Realtime ─────────────────────────────────────────────────────────────────

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_participants;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.chats;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_posts;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_comments;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_titles;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.creator_videos;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- ── Storage Buckets ───────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public) VALUES
  ('creator-videos',     'creator-videos',     true),
  ('creator-thumbnails', 'creator-thumbnails', true),
  ('avatars',            'avatars',            true),
  ('community-media',    'community-media',    true)
ON CONFLICT (id) DO NOTHING;

-- Storage: creator videos
DROP POLICY IF EXISTS "Creators upload videos" ON storage.objects;
CREATE POLICY "Creators upload videos" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'creator-videos'
    AND auth.uid()::text = (storage.foldername(name))[1]
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'creator' AND creator_status = 'approved'
    )
  );
DROP POLICY IF EXISTS "Public read videos" ON storage.objects;
CREATE POLICY "Public read videos"        ON storage.objects FOR SELECT USING (bucket_id = 'creator-videos');
DROP POLICY IF EXISTS "Creators delete own videos" ON storage.objects;
CREATE POLICY "Creators delete own videos" ON storage.objects FOR DELETE
  USING (bucket_id = 'creator-videos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage: thumbnails
DROP POLICY IF EXISTS "Creators upload thumbnails" ON storage.objects;
CREATE POLICY "Creators upload thumbnails" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'creator-thumbnails' AND auth.uid()::text = (storage.foldername(name))[1]);
DROP POLICY IF EXISTS "Public read thumbnails" ON storage.objects;
CREATE POLICY "Public read thumbnails" ON storage.objects FOR SELECT USING (bucket_id = 'creator-thumbnails');

-- Storage: avatars
DROP POLICY IF EXISTS "Users upload avatars" ON storage.objects;
CREATE POLICY "Users upload avatars" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
DROP POLICY IF EXISTS "Public read avatars" ON storage.objects;
CREATE POLICY "Public read avatars"      ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
DROP POLICY IF EXISTS "Users delete own avatars" ON storage.objects;
CREATE POLICY "Users delete own avatars" ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Storage: community media (path convention: community_id/user_id/filename)
DROP POLICY IF EXISTS "Members upload community media" ON storage.objects;
CREATE POLICY "Members upload community media" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'community-media'
    AND (storage.foldername(name))[2] = auth.uid()::text
    AND EXISTS (
      SELECT 1 FROM public.community_members
      WHERE community_id = (storage.foldername(name))[1]::bigint AND user_id = auth.uid()
    )
  );
DROP POLICY IF EXISTS "Public read community media" ON storage.objects;
CREATE POLICY "Public read community media"       ON storage.objects FOR SELECT USING (bucket_id = 'community-media');
DROP POLICY IF EXISTS "Users delete own community media" ON storage.objects;
CREATE POLICY "Users delete own community media"  ON storage.objects FOR DELETE
  USING (bucket_id = 'community-media' AND (storage.foldername(name))[2] = auth.uid()::text);

-- ── Partition Auto-Maintenance Function ───────────────────────────────────────
-- Consolidated from migrations 13 and 20260413000001.
-- Creates next month's partitions for messages, video_engagement_events, and feed_impressions.

CREATE OR REPLACE FUNCTION public.create_next_month_partitions()
RETURNS void AS $$
DECLARE
  next_start  DATE := date_trunc('month', now() + interval '1 month');
  next_end    DATE := date_trunc('month', now() + interval '2 months');
  suffix      TEXT := to_char(next_start, 'YYYY_MM');
BEGIN
  -- messages
  IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = 'public' AND c.relname = 'msg_' || suffix) THEN
    EXECUTE format('CREATE TABLE public.%I PARTITION OF public.messages FOR VALUES FROM (%L) TO (%L)',
                   'msg_' || suffix, next_start, next_end);
    RAISE NOTICE 'Created partition msg_%', suffix;
  END IF;

  -- video_engagement_events
  IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = 'public' AND c.relname = 'vee_' || suffix) THEN
    EXECUTE format('CREATE TABLE public.%I PARTITION OF public.video_engagement_events FOR VALUES FROM (%L) TO (%L)',
                   'vee_' || suffix, next_start, next_end);
    RAISE NOTICE 'Created partition vee_%', suffix;
  END IF;

  -- feed_impressions
  IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                 WHERE n.nspname = 'public' AND c.relname = 'fi_' || suffix) THEN
    EXECUTE format('CREATE TABLE public.%I PARTITION OF public.feed_impressions FOR VALUES FROM (%L) TO (%L)',
                   'fi_' || suffix, next_start, next_end);
    RAISE NOTICE 'Created partition fi_%', suffix;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── pg_cron Jobs ─────────────────────────────────────────────────────────────
-- All previously-commented-out cron jobs are now live.

-- 1. Feed rankings — every 15 minutes
SELECT cron.schedule(
  'compute-feed-rankings',
  '*/15 * * * *',
  $$SELECT public.compute_feed_rankings()$$
);

-- 2. Creator trust scores — every 6 hours
SELECT cron.schedule(
  'compute-creator-trust-scores',
  '0 */6 * * *',
  $$SELECT public.compute_creator_trust_scores()$$
);

-- 3. Counter flush — every 30 seconds
-- Note: pg_cron minimum resolution is 1 minute. Use an Edge Function on a 30s timer
-- OR accept 1-minute flush granularity:
SELECT cron.schedule(
  'flush-counter-events',
  '* * * * *',   -- every minute (pg_cron minimum)
  $$SELECT public.flush_counter_events()$$
);

-- 4. Creator daily stats — daily at 01:00 UTC
SELECT cron.schedule(
  'compute-creator-daily-stats',
  '0 1 * * *',
  $$SELECT public.compute_creator_daily_stats()$$
);

-- 5. Trending hashtags — every 15 minutes
SELECT cron.schedule(
  'compute-trending-hashtags',
  '*/15 * * * *',
  $$SELECT public.compute_trending_hashtags()$$
);

-- 6. Monthly partition creation — 1st of every month at 00:05 UTC
SELECT cron.schedule(
  'create-monthly-partitions',
  '5 0 1 * *',
  $$SELECT public.create_next_month_partitions()$$
);

-- 7. Score snapshot TTL cleanup — daily at 03:00 UTC
-- FIX: was documented as a TODO but never scheduled.
SELECT cron.schedule(
  'cleanup-score-snapshots',
  '0 3 * * *',
  $$DELETE FROM public.video_score_snapshots WHERE computed_at < now() - interval '30 days'$$
);

-- ── Verify scheduled jobs ─────────────────────────────────────────────────────
-- Run in SQL editor to confirm:
--
--   SELECT jobname, schedule, active FROM cron.job ORDER BY jobname;
