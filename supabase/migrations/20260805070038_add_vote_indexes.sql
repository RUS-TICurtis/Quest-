CREATE INDEX IF NOT EXISTS idx_comment_votes_user_comment ON public.comment_votes(user_id, comment_id);
CREATE INDEX IF NOT EXISTS idx_post_votes_user_post ON public.post_votes(user_id, post_id);
