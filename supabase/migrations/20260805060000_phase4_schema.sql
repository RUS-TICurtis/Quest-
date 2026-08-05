-- Phase 4 Schema Extensions for Quest

-- 1. Create Profiles Table (extends auth.users)
CREATE TABLE public.profiles (
  "id" uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  "name" text NOT NULL,
  "initials" text,
  "level" int DEFAULT 1,
  "currentXp" int DEFAULT 0,
  "xpToNextLevel" int DEFAULT 100,
  "streak" int DEFAULT 0,
  "archetypes" text[] DEFAULT '{}',
  "badges" text[] DEFAULT '{}',
  "joinedCommunityIds" text[] DEFAULT '{}',
  "rsvpdEventIds" text[] DEFAULT '{}',
  "recentlyLeveledUp" boolean DEFAULT false,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Radar Nodes Table
CREATE TABLE public.radar_nodes (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "name" text NOT NULL,
  "address" text NOT NULL,
  "category" text NOT NULL,
  "activeMembersCount" int DEFAULT 0,
  "distanceMiles" numeric DEFAULT 0.0,
  "isVerified" boolean DEFAULT true,
  "xpBonus" int DEFAULT 150,
  "imageUrl" text NOT NULL,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create Stage Rooms Table
CREATE TABLE public.stage_rooms (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "name" text NOT NULL,
  "description" text,
  "hostId" uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  "isActive" boolean DEFAULT true,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Create Chat Messages Table
CREATE TABLE public.chat_messages (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "text" text NOT NULL,
  "isMe" boolean DEFAULT false,
  "time" text NOT NULL,
  "type" text DEFAULT 'text',
  "voiceDurationSeconds" int DEFAULT 0,
  "audioDuration" text,
  "waveform" numeric[],
  "linkTitle" text,
  "linkSubtitle" text,
  "linkTargetRoute" text,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Daily Quests table (for user's daily quests)
CREATE TABLE public.daily_quests (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "userId" uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  "title" text NOT NULL,
  "xp" int NOT NULL,
  "isDone" boolean DEFAULT false,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.radar_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stage_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_quests ENABLE ROW LEVEL SECURITY;

-- 6. Create permissive policies for development
CREATE POLICY "Allow public read access to profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow public insert to profiles" ON public.profiles FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update to profiles" ON public.profiles FOR UPDATE USING (true);

CREATE POLICY "Allow public read access to radar_nodes" ON public.radar_nodes FOR SELECT USING (true);
CREATE POLICY "Allow public insert to radar_nodes" ON public.radar_nodes FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public read access to stage_rooms" ON public.stage_rooms FOR SELECT USING (true);
CREATE POLICY "Allow public insert to stage_rooms" ON public.stage_rooms FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public read access to chat_messages" ON public.chat_messages FOR SELECT USING (true);
CREATE POLICY "Allow public insert to chat_messages" ON public.chat_messages FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public read access to daily_quests" ON public.daily_quests FOR SELECT USING (true);
CREATE POLICY "Allow public insert to daily_quests" ON public.daily_quests FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update to daily_quests" ON public.daily_quests FOR UPDATE USING (true);
