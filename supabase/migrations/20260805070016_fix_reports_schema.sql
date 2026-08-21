-- Fix naming and add missing columns to reports table
ALTER TABLE public.reports ADD COLUMN IF NOT EXISTS community_id BIGINT REFERENCES public.communities(id);
ALTER TABLE public.reports ADD COLUMN IF NOT EXISTS chat_id UUID REFERENCES public.chats(id);

-- Ensure RLS is updated (already enabled, but good to be explicit)
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
