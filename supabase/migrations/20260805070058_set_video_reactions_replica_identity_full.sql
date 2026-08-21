-- Set REPLICA IDENTITY FULL on public.video_reactions so DELETE events broadcast the entire row.
-- Without this, delete events only broadcast the primary key (id), meaning the client cannot
-- resolve which video_id was unliked for cross-device real-time syncing.
ALTER TABLE public.video_reactions REPLICA IDENTITY FULL;
