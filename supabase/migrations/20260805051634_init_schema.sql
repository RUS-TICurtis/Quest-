-- Quest Initial Schema for Supabase
-- Paste this script into your Supabase SQL Editor and run it to create your database!

-- 1. Create Communities Table
CREATE TABLE public.communities (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "name" text NOT NULL,
  "description" text NOT NULL,
  "category" text NOT NULL,
  "memberCount" int DEFAULT 1,
  "accentColor" bigint,
  "icon" int,
  "tags" text[] DEFAULT '{}',
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Events Table
CREATE TABLE public.events (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "communityId" uuid REFERENCES public.communities(id) ON DELETE CASCADE,
  "title" text NOT NULL,
  "host" text NOT NULL,
  "date" text NOT NULL,
  "time" text NOT NULL,
  "location" text NOT NULL,
  "attendeesCount" int DEFAULT 0,
  "imageUrl" text,
  "category" text NOT NULL,
  "accentColor" bigint,
  "description" text NOT NULL,
  "xpReward" int DEFAULT 150,
  "isRsvpd" boolean DEFAULT false,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create Stories Table
CREATE TABLE public.stories (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "authorName" text NOT NULL,
  "communityName" text DEFAULT 'Community',
  "caption" text,
  "ringColor" bigint,
  "icon" int,
  "isSeen" boolean DEFAULT false,
  "timeAgo" text NOT NULL,
  "authorAvatar" text,
  "title" text,
  "content" text,
  "gradient" bigint[],
  "isSpoiler" boolean DEFAULT false,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Create Leaderboard Table
CREATE TABLE public.leaderboard (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "userId" uuid, -- normally references auth.users
  "rank" int NOT NULL,
  "name" text NOT NULL,
  "score" int NOT NULL,
  "trend" text NOT NULL,
  "avatarUrl" text,
  "isCurrentUser" boolean DEFAULT false,
  "badge" text,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;

-- 6. Create permissive policies for development (WARNING: Restrict these before production!)
CREATE POLICY "Allow public read access to communities" ON public.communities FOR SELECT USING (true);
CREATE POLICY "Allow public read access to events" ON public.events FOR SELECT USING (true);
CREATE POLICY "Allow public read access to stories" ON public.stories FOR SELECT USING (true);
CREATE POLICY "Allow public read access to leaderboard" ON public.leaderboard FOR SELECT USING (true);

-- Allow public inserts for development
CREATE POLICY "Allow public insert to communities" ON public.communities FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public insert to events" ON public.events FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public insert to stories" ON public.stories FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public insert to leaderboard" ON public.leaderboard FOR INSERT WITH CHECK (true);
