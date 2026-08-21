-- Create the user_video_views table for deduplication
CREATE TABLE IF NOT EXISTS public.user_video_views (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  video_id uuid NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  PRIMARY KEY (user_id, video_id)
);

-- Enable RLS
ALTER TABLE public.user_video_views ENABLE ROW LEVEL SECURITY;

-- Strict per-user access policies
CREATE POLICY "Users can manage their own views"
ON public.user_video_views
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_video_views_user ON public.user_video_views(user_id);
CREATE INDEX IF NOT EXISTS idx_user_video_views_recent ON public.user_video_views(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_video_views_covering ON public.user_video_views(user_id, video_id, created_at DESC);

-- Modify existing append_seen_videos to dual-write
CREATE OR REPLACE FUNCTION public.append_seen_videos(p_session_id UUID, p_new_ids UUID[])
RETURNS void AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get user_id for the session
  SELECT user_id INTO v_user_id FROM public.feed_sessions WHERE id = p_session_id;

  -- 1. Dual write to new user_video_views table
  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.user_video_views (user_id, video_id)
    SELECT v_user_id, unnest(p_new_ids)
    ON CONFLICT (user_id, video_id) DO UPDATE SET created_at = now();
  END IF;

  -- 2. Keep existing array logic (backward compatibility)
  UPDATE public.feed_sessions
  SET seen_video_ids = (SELECT array_agg(DISTINCT u) FROM unnest(seen_video_ids || p_new_ids) u),
      updated_at = now()
  WHERE id = p_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Data Migration: Migrate existing seen_video_ids from feed_sessions to user_video_views
DO $$
BEGIN
  INSERT INTO public.user_video_views (user_id, video_id)
  SELECT fs.user_id, unnest(fs.seen_video_ids) AS video_id
  FROM public.feed_sessions fs
  WHERE fs.user_id IS NOT NULL AND fs.seen_video_ids IS NOT NULL AND array_length(fs.seen_video_ids, 1) > 0
  ON CONFLICT (user_id, video_id) DO NOTHING;
END $$;
