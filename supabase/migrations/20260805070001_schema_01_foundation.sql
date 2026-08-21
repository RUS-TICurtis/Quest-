-- ============================================================================
-- SCHEMA GROUP 1: Foundation
-- Extensions, lookup tables, profiles, identity, social graph
-- ============================================================================

-- ── Extensions ───────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm     SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_net      SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_cron     SCHEMA pg_catalog;

GRANT USAGE ON SCHEMA cron TO postgres;

-- ── Lookup / Enum Tables ─────────────────────────────────────────────────────

CREATE TABLE public.media_types          (value TEXT PRIMARY KEY);
CREATE TABLE public.user_title_statuses  (value TEXT PRIMARY KEY);
CREATE TABLE public.reaction_types       (value TEXT PRIMARY KEY);
CREATE TABLE public.report_types         (value TEXT PRIMARY KEY);
CREATE TABLE public.report_statuses      (value TEXT PRIMARY KEY);
CREATE TABLE public.application_statuses (value TEXT PRIMARY KEY);
CREATE TABLE public.feed_categories      (value TEXT PRIMARY KEY);
CREATE TABLE public.message_types        (value TEXT PRIMARY KEY);
CREATE TABLE public.user_roles           (value TEXT PRIMARY KEY);
CREATE TABLE public.community_roles      (value TEXT PRIMARY KEY);
CREATE TABLE public.activity_types       (value TEXT PRIMARY KEY);  -- FIX: was free-text

INSERT INTO public.media_types          VALUES ('movie'), ('tv');
INSERT INTO public.user_title_statuses  VALUES ('watchlist'), ('watching'), ('finished'), ('dropped');
INSERT INTO public.reaction_types       VALUES ('heart'), ('laugh'), ('wow'), ('sad'), ('angry');
INSERT INTO public.report_types         VALUES
  ('community_post'), ('community_comment'), ('chat_message'),
  ('video_comment'), ('user_profile'), ('creator_video');
INSERT INTO public.report_statuses      VALUES ('pending'), ('reviewed'), ('resolved'), ('ignored'), ('dismissed');
INSERT INTO public.application_statuses VALUES ('pending'), ('approved'), ('rejected'), ('suspended');
INSERT INTO public.feed_categories      VALUES ('for_you'), ('trending'), ('following');
INSERT INTO public.message_types        VALUES
  ('text'), ('image'), ('video'), ('video_link'), ('recommendation'),
  ('shared_post'), ('video_share'), ('gif'), ('sticker'), ('meme');  -- FIX: shared_post was added late
INSERT INTO public.user_roles           VALUES ('user'), ('creator'), ('reviewer'), ('admin');
INSERT INTO public.community_roles      VALUES ('member'), ('moderator'), ('admin');
INSERT INTO public.activity_types       VALUES
  ('follow'), ('like'), ('comment'), ('post'), ('share'), ('join_community'), ('upload');

-- RLS: all lookup tables are public read-only, no write from clients

DO $$
DECLARE t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY[
    'media_types','user_title_statuses','reaction_types','report_types',
    'report_statuses','application_statuses','feed_categories',
    'message_types','user_roles','community_roles','activity_types'
  ]) LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('CREATE POLICY "Public read %s" ON public.%I FOR SELECT USING (true)', t, t);
  END LOOP;
END $$;

-- ── Admin role helper (DRY up repeated RLS subqueries) ───────────────────────
-- FIX: was repeated ~20 times inline; centralised here for maintainability.

CREATE OR REPLACE FUNCTION public.is_admin_or_reviewer()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'reviewer')
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ── Profiles ──────────────────────────────────────────────────────────────────

CREATE TABLE public.profiles (
  id                        UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  username                  TEXT UNIQUE,
  display_name              TEXT,              -- full display name, required by admin app
  first_name                TEXT,
  last_name                 TEXT,
  bio                       TEXT,               -- was added in migration 18
  description               TEXT,              -- was added in migration 18
  avatar_url                TEXT,
  role                      TEXT DEFAULT 'user' REFERENCES public.user_roles(value),
  creator_status            TEXT REFERENCES public.application_statuses(value),
  creator_verified_at       TIMESTAMPTZ,
  is_banned                 BOOLEAN DEFAULT false,
  is_suspended              BOOLEAN DEFAULT false,
  suspension_end_timestamp  TIMESTAMPTZ,
  suspension_reason         TEXT,
  ban_reason                TEXT,
  reputation_score          NUMERIC DEFAULT 0,
  is_shadowbanned           BOOLEAN DEFAULT false,
  preferences               JSONB DEFAULT '{}'::jsonb,
  onboarding_completed      BOOLEAN DEFAULT false,
  firebase_uid              TEXT UNIQUE,
  created_at                TIMESTAMPTZ DEFAULT now(),
  updated_at                TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_profiles_role           ON public.profiles(role);
CREATE INDEX idx_profiles_creator_status ON public.profiles(creator_status) WHERE creator_status IS NOT NULL;

CREATE TRIGGER handle_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

-- Auto-create profile on signup
-- FIX: username length capped and sanitised to prevent abuse via raw_user_meta_data
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  _username     TEXT;
  _display_name TEXT;
  _first_name   TEXT;
  _last_name    TEXT;
BEGIN
  _username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );
  -- FIX: sanitize and truncate username; raw_user_meta_data is user-editable
  _username  := left(regexp_replace(trim(_username), '[^a-zA-Z0-9_\.]', '', 'g'), 30);
  IF length(_username) < 1 THEN _username := 'user_' || substring(NEW.id::text, 1, 8); END IF;

  _first_name := COALESCE(
    NEW.raw_user_meta_data->>'first_name',
    NULLIF(split_part(COALESCE(NEW.raw_user_meta_data->>'full_name', ''), ' ', 1), '')
  );
  _last_name := COALESCE(
    NEW.raw_user_meta_data->>'last_name',
    NULLIF(split_part(COALESCE(NEW.raw_user_meta_data->>'full_name', ''), ' ', 2), '')
  );

  -- Build display_name: prefer explicit full_name, else first+last, else username
  _display_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''),
    NULLIF(trim(COALESCE(_first_name, '') || ' ' || COALESCE(_last_name, '')), ''),
    _username
  );

  INSERT INTO public.profiles (id, username, display_name, first_name, last_name)
  VALUES (NEW.id, _username, _display_name, _first_name, _last_name)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read profiles"     ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins update any profile" ON public.profiles FOR UPDATE
  USING (public.is_admin_or_reviewer());

-- ── Creator Applications ──────────────────────────────────────────────────────

CREATE TABLE public.creator_applications (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  display_name   TEXT NOT NULL,
  bio            TEXT NOT NULL,
  content_intent TEXT[],
  external_links JSONB,
  status         TEXT DEFAULT 'pending' REFERENCES public.application_statuses(value),
  reviewed_by    UUID REFERENCES public.profiles(id),
  review_notes   TEXT,
  created_at     TIMESTAMPTZ DEFAULT now(),
  reviewed_at    TIMESTAMPTZ,
  CONSTRAINT unique_pending_application UNIQUE (user_id, status)
);

CREATE INDEX idx_creator_apps_user   ON public.creator_applications(user_id);
CREATE INDEX idx_creator_apps_status ON public.creator_applications(status);

CREATE OR REPLACE FUNCTION public.has_pending_application(p_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.creator_applications
    WHERE user_id = p_user_id AND status = 'pending'
  );
$$ LANGUAGE sql SECURITY DEFINER;

ALTER TABLE public.creator_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own applications"  ON public.creator_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users submit applications"    ON public.creator_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins view all applications" ON public.creator_applications FOR SELECT USING (public.is_admin_or_reviewer());
CREATE POLICY "Admins update applications"   ON public.creator_applications FOR UPDATE USING (public.is_admin_or_reviewer());

-- ── Appeals ───────────────────────────────────────────────────────────────────

CREATE TABLE public.appeals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- FIX: was free-text; using CHECK to constrain to known types
  action_type     TEXT NOT NULL CHECK (action_type IN ('ban', 'suspension', 'rejection', 'removal', 'other')),
  original_reason TEXT,
  appeal_message  TEXT NOT NULL,
  status          TEXT DEFAULT 'pending' REFERENCES public.application_statuses(value),
  admin_notes     TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER handle_appeals_updated_at
  BEFORE UPDATE ON public.appeals
  FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

ALTER TABLE public.appeals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own appeals"  ON public.appeals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users submit appeals"    ON public.appeals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins manage appeals"   ON public.appeals FOR ALL USING (public.is_admin_or_reviewer());

-- ── Social Graph: Follows & Blocks ───────────────────────────────────────────

CREATE TABLE public.follows (
  follower_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE INDEX idx_follows_follower  ON public.follows(follower_id);
CREATE INDEX idx_follows_following ON public.follows(following_id);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read follows" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Users can follow"    ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow"  ON public.follows FOR DELETE  USING (auth.uid() = follower_id);

CREATE TABLE public.user_blocks (
  blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)
);

CREATE INDEX idx_blocks_blocker ON public.user_blocks(blocker_id);
CREATE INDEX idx_blocks_blocked ON public.user_blocks(blocked_id);

ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own blocks" ON public.user_blocks FOR SELECT USING (auth.uid() = blocker_id);
CREATE POLICY "Users can block"       ON public.user_blocks FOR INSERT WITH CHECK (auth.uid() = blocker_id);
CREATE POLICY "Users can unblock"     ON public.user_blocks FOR DELETE  USING (auth.uid() = blocker_id);

-- ── Activities (Friend Feed & Trending Signals) ───────────────────────────────
-- FIX: `type` was unconstrained TEXT; now references activity_types lookup table.

CREATE TABLE public.activities (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type         TEXT NOT NULL REFERENCES public.activity_types(value),
  reference_id UUID,
  metadata     JSONB DEFAULT '{}'::jsonb,
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_activities_feed     ON public.activities(user_id, created_at DESC);
CREATE INDEX idx_activities_type_ref ON public.activities(type, reference_id);

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read activities"      ON public.activities FOR SELECT USING (true);
CREATE POLICY "Users insert own activities" ON public.activities FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ── User Trust Scores ─────────────────────────────────────────────────────────

CREATE TABLE public.user_trust_scores (
  user_id            UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  trust_score        NUMERIC(5,4) DEFAULT 1.0 CHECK (trust_score BETWEEN 0 AND 1),
  reports_received   INT DEFAULT 0,
  false_reports_made INT DEFAULT 0,
  actions_taken      INT DEFAULT 0,
  updated_at         TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.user_trust_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own trust"     ON public.user_trust_scores FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins view all trust"    ON public.user_trust_scores FOR SELECT USING (public.is_admin_or_reviewer());
