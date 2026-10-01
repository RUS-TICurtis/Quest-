-- ==========================================
-- Quest Phase 3 Mock Seed Data Migration
-- ==========================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 0. SEED AUTH USERS
INSERT INTO auth.users (
  id, 
  aud, 
  role, 
  email, 
  raw_app_meta_data, 
  raw_user_meta_data, 
  created_at, 
  updated_at
) VALUES 
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', 'curtis_mock@quest.app', '{"provider":"email","providers":["email"]}', '{"name":"curtis_quest"}', now(), now()),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', 'jane_mock@quest.app', '{"provider":"email","providers":["email"]}', '{"name":"jane_doe"}', now(), now()),
  ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', 'john_mock@quest.app', '{"provider":"email","providers":["email"]}', '{"name":"john_smith"}', now(), now())
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email;

-- 1. SEED PROFILES & TRUST SCORES
INSERT INTO public.profiles (id, name, username, avatar_url, bio, archetypes, level, "currentXp")
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'Curtis', 'curtis_quest', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200', 'Explorer of digital realms and community leader.', ARRAY['Adventurer', 'Creator'], 12, 450),
  ('22222222-2222-2222-2222-222222222222', 'Jane Doe', 'jane_doe', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200', 'Building vibrant open communities.', ARRAY['Leader', 'Connector'], 9, 210),
  ('33333333-3333-3333-3333-333333333333', 'John Smith', 'john_smith', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200', 'Organizing epic local events and quests.', ARRAY['Organizer', 'Strategist'], 15, 890)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  username = EXCLUDED.username,
  avatar_url = EXCLUDED.avatar_url,
  bio = EXCLUDED.bio,
  archetypes = EXCLUDED.archetypes;

-- User Trust Scores
INSERT INTO public.user_trust_scores (user_id, score, level)
VALUES 
  ('11111111-1111-1111-1111-111111111111', 95.5, 'Platinum'),
  ('22222222-2222-2222-2222-222222222222', 88.0, 'Gold'),
  ('33333333-3333-3333-3333-333333333333', 75.0, 'Silver')
ON CONFLICT (user_id) DO UPDATE SET
  score = EXCLUDED.score,
  level = EXCLUDED.level;

-- 2. SEED COMMUNITIES
INSERT INTO public.communities (id, name, description, category, "memberCount", "accentColor", tags)
VALUES 
  ('44444444-4444-4444-4444-444444444444', 'Tech Innovators', 'A place for exploring emerging technology, AI agents, and next-gen tools.', 'Tech', 245, 4280391411, ARRAY['AI', 'Code', 'Web3']),
  ('55555555-5555-5555-5555-555555555555', 'Local Runners & Hikers', 'Weekly group runs, trail exploration, and fitness milestones.', 'Fitness', 128, 4283151471, ARRAY['Running', 'Outdoors', 'Health']),
  ('66666666-6666-6666-6666-666666666666', 'Creative Designers', 'UI/UX workshops, motion design, design critiques, and typography.', 'Design', 312, 4287247783, ARRAY['UIUX', 'Figma', 'Art'])
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description;

-- 3. SEED EVENTS
INSERT INTO public.events (id, "communityId", title, host, date, time, location, "attendeesCount", "imageUrl", category, description, "xpReward")
VALUES 
  ('77777777-7777-7777-7777-777777777777', '44444444-4444-4444-4444-444444444444', 'AI Developers Meetup', 'Curtis', 'Tomorrow', '6:00 PM', 'San Francisco Innovation Hub', 45, 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600', 'Tech', 'Hands-on demos of local LLMs and agent frameworks.', 250),
  ('88888888-8888-8888-8888-888888888888', '55555555-5555-5555-5555-555555555555', 'Sunset Park 5K', 'John Smith', 'Saturday', '7:00 AM', 'Golden Gate Park', 32, 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=600', 'Fitness', 'Scenic morning run followed by coffee and stretch.', 150),
  ('99999999-9999-9999-9999-999999999999', '66666666-6666-6666-6666-666666666666', 'Design System Architecture', 'Jane Doe', 'Friday', '5:30 PM', 'Virtual Discord Stage', 85, 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8?w=600', 'Design', 'Creating scalable design tokens and fluid component libraries.', 200)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title;

-- 4. SEED DAILY QUESTS
INSERT INTO public.daily_quests (id, "userId", title, xp, "isDone")
VALUES 
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Complete 1 Community Discussion', 100, false),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'RSVP to an Upcoming Event', 150, true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '11111111-1111-1111-1111-111111111111', 'Explore 3 Video Creator Feeds', 75, false)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title;

-- 5. SEED UNIFIED VIDEOS
INSERT INTO public.videos (id, user_id, video_type, video_url, thumbnail_url, title, description, duration_seconds, trust_score, like_count, comment_count, view_count)
VALUES 
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'feed', 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8', 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400', 'Big Buck Bunny (HLS Stream)', 'Testing the live Mux HLS streaming pipeline on Quest video feed.', 30, 95.5, 38, 5, 142),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', '22222222-2222-2222-2222-222222222222', 'feed', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=400', 'Epic Quest Journey Vlog', 'Sharing my journey through modern questing and tech communities.', 45, 88.0, 56, 12, 389),
  ('ffffffff-ffff-ffff-ffff-ffffffffffff', '33333333-3333-3333-3333-333333333333', 'story', 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400', 'Event Behind The Scenes', 'Quick glimpse from the backstage tech setup!', 15, 75.0, 19, 2, 88)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title;
