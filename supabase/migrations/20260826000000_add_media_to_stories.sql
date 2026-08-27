-- Add Mux and Cloudinary support to Stories
ALTER TABLE public.stories
ADD COLUMN "media_url" text,
ADD COLUMN "mux_playback_id" text,
ADD COLUMN "user_id" uuid REFERENCES auth.users(id);
