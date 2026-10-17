-- ==============================================================================
-- Quest Schema Migration: Beacons / Spontaneous Meetups
-- Created: 2026-10-17
-- Description: Adds beacons table, RLS policies, and attendee tracking for
--              spontaneous location-based fellowship and meetups.
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.beacons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    creator_name TEXT NOT NULL,
    creator_avatar TEXT NOT NULL DEFAULT '',
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    hub_id TEXT NOT NULL,
    hub_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    expires_at TIMESTAMPTZ NOT NULL,
    attendee_ids UUID[] NOT NULL DEFAULT '{}',
    attendee_avatars TEXT[] NOT NULL DEFAULT '{}',
    xp_reward INTEGER NOT NULL DEFAULT 50,
    angle_ratio DOUBLE PRECISION NOT NULL DEFAULT 0.35,
    radius_ratio DOUBLE PRECISION NOT NULL DEFAULT 0.55
);

-- Index on expires_at and hub_id for rapid radar polling
CREATE INDEX IF NOT EXISTS idx_beacons_active ON public.beacons (hub_id, expires_at);
CREATE INDEX IF NOT EXISTS idx_beacons_creator ON public.beacons (creator_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.beacons ENABLE ROW LEVEL SECURITY;

-- 1. Anyone authenticated can read active (non-expired) beacons
CREATE POLICY "Anyone can view active beacons"
    ON public.beacons FOR SELECT
    TO authenticated
    USING (expires_at > timezone('utc'::text, now()));

-- 2. Authenticated members can insert their own beacons
CREATE POLICY "Authenticated users can create beacons"
    ON public.beacons FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = creator_id);

-- 3. Authenticated members can join beacons (update attendee lists)
CREATE POLICY "Authenticated users can update attendee lists"
    ON public.beacons FOR UPDATE
    TO authenticated
    USING (expires_at > timezone('utc'::text, now()))
    WITH CHECK (expires_at > timezone('utc'::text, now()));

-- 4. Creators can delete or cancel their own beacons
CREATE POLICY "Creators can delete their own beacons"
    ON public.beacons FOR DELETE
    TO authenticated
    USING (auth.uid() = creator_id);

-- 5. Auto-expire beacons via pg_cron (runs hourly to clean up expired beacons)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'cleanup_expired_beacons',
      '0 * * * *',
      $cron$
        DELETE FROM public.beacons
        WHERE expires_at < timezone('utc'::text, now());
      $cron$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Gracefully ignore if pg_cron functions are unavailable in local or staging environment
  NULL;
END $$;

