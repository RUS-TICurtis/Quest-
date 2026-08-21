-- Create external_videos table
CREATE TABLE IF NOT EXISTS public.external_videos (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    thumbnail_url TEXT,
    video_url TEXT NOT NULL,
    category TEXT NOT NULL,
    source TEXT NOT NULL,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.external_videos ENABLE ROW LEVEL SECURITY;

-- Allow public read access to external_videos
CREATE POLICY "Allow public read access on external_videos"
ON public.external_videos FOR SELECT
USING (true);

-- Allow service role to insert/update (Edge Function will use service role)
CREATE POLICY "Allow service role full access on external_videos"
ON public.external_videos FOR ALL
USING (auth.jwt()->>'role' = 'service_role');
