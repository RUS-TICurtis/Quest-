-- Migration: Allow deleting user_video_views
-- Enables clients to clear/reset their seen video history for personalized recommendation feeds.

CREATE POLICY "Users delete own views"
  ON public.user_video_views FOR DELETE
  USING (auth.uid() = user_id);
