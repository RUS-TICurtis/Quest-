import re

file1 = 'supabase/migrations/20260805070001_schema_01_foundation.sql'
with open(file1, 'r', encoding='utf-8') as f:
    content1 = f.read()

replacement1 = '''CREATE TABLE IF NOT EXISTS public.profiles (
  id                        UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY
);

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username                  TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS display_name              TEXT,
  ADD COLUMN IF NOT EXISTS first_name                TEXT,
  ADD COLUMN IF NOT EXISTS last_name                 TEXT,
  ADD COLUMN IF NOT EXISTS bio                       TEXT,
  ADD COLUMN IF NOT EXISTS description               TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url                TEXT,
  ADD COLUMN IF NOT EXISTS role                      TEXT DEFAULT 'user' REFERENCES public.user_roles(value),
  ADD COLUMN IF NOT EXISTS creator_status            TEXT REFERENCES public.application_statuses(value),
  ADD COLUMN IF NOT EXISTS creator_verified_at       TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_banned                 BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_suspended              BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS suspension_end_timestamp  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS suspension_reason         TEXT,
  ADD COLUMN IF NOT EXISTS ban_reason                TEXT,
  ADD COLUMN IF NOT EXISTS reputation_score          NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_shadowbanned           BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS preferences               JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS onboarding_completed      BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS firebase_uid              TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS created_at                TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at                TIMESTAMPTZ DEFAULT now();'''

content1 = re.sub(r'CREATE TABLE public\.profiles \([\s\S]*?\);', replacement1, content1)

with open(file1, 'w', encoding='utf-8') as f:
    f.write(content1)

file2 = 'supabase/migrations/20260805070002_schema_02_content.sql'
with open(file2, 'r', encoding='utf-8') as f:
    content2 = f.read()

replacement2 = '''CREATE TABLE IF NOT EXISTS public.communities (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

ALTER TABLE public.communities
  ADD COLUMN IF NOT EXISTS created_at       TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS owner_id         UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS name             TEXT,
  ADD COLUMN IF NOT EXISTS description      TEXT,
  ADD COLUMN IF NOT EXISTS rules            TEXT,
  ADD COLUMN IF NOT EXISTS is_private       BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS banner_url       TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url       TEXT,
  ADD COLUMN IF NOT EXISTS total_members    INT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS total_posts      INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS trending_score   NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_activity_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS metadata         JSONB DEFAULT '{}'::jsonb;'''

content2 = re.sub(r'CREATE TABLE public\.communities \([\s\S]*?\);', replacement2, content2)

with open(file2, 'w', encoding='utf-8') as f:
    f.write(content2)

print("Migration files rewritten!")
