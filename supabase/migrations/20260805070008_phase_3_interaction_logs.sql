-- Create interaction_logs table
CREATE TABLE IF NOT EXISTS public.interaction_logs (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  video_id uuid NOT NULL REFERENCES public.creator_videos(id) ON DELETE CASCADE,
  action text NOT NULL, -- 'view', 'like', 'share', 'comment'
  watch_time_ms integer,
  duration_ms integer,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.interaction_logs ENABLE ROW LEVEL SECURITY;

-- Users can insert their own logs
CREATE POLICY "Users can insert their own interaction logs"
ON public.interaction_logs
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can read their own logs (if needed for history)
CREATE POLICY "Users can view their own interaction logs"
ON public.interaction_logs
FOR SELECT
USING (auth.uid() = user_id);

-- Add index for fast querying by background jobs
CREATE INDEX IF NOT EXISTS idx_interaction_logs_unprocessed ON public.interaction_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_interaction_logs_user_video ON public.interaction_logs(user_id, video_id);
