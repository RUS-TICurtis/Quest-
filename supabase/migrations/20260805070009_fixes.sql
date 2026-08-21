-- Migration to fix multiple issues:
-- 1. UUID mismatch / duplicated messages: Add REPLICA IDENTITY FULL to chats so updates send the whole row.
-- 2. Communities RLS: Add a strict policy so members can't arbitrarily update communities.
-- 3. Security Definer in increment_video_shares: Check auth.uid().
-- 4. Partition maintenance: Add SECURITY DEFINER to create_next_month_partitions.

-- 1. Chats REPLICA IDENTITY FULL for inbox sync
ALTER TABLE public.chats REPLICA IDENTITY FULL;

-- 2. Communities RLS
-- Remove the old policy if it allowed arbitrary updates (we only saw Admins manage communities, but let's be safe and ensure no open UPDATE exists).
-- Let's ensure only creators of the community can update it.
DROP POLICY IF EXISTS "Users update own communities" ON public.communities;
CREATE POLICY "Users update own communities" ON public.communities 
  FOR UPDATE USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());

-- 3. Secure increment_video_shares RPC
CREATE OR REPLACE FUNCTION public.increment_video_shares(p_video_id UUID)
RETURNS void AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  UPDATE public.creator_videos SET share_count = share_count + 1 WHERE id = p_video_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_video_views(p_video_id UUID)
RETURNS void AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  UPDATE public.creator_videos SET view_count = view_count + 1 WHERE id = p_video_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_video_likes(p_video_id UUID)
RETURNS void AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  UPDATE public.creator_videos SET like_count = like_count + 1 WHERE id = p_video_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.decrement_video_likes(p_video_id UUID)
RETURNS void AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  UPDATE public.creator_videos SET like_count = GREATEST(like_count - 1, 0) WHERE id = p_video_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4. Partition Auto-Maintenance Function fix
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
