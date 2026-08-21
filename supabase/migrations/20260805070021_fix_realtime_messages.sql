-- ============================================================================
-- FIX: Supabase Realtime not firing for chat messages
--
-- Root Cause:
--   The `messages` table is PARTITIONED BY RANGE (created_at). Postgres
--   Logical Replication (which Supabase Realtime relies on) emits WAL events
--   from the CHILD partition tables (e.g. msg_2026_04), NOT the parent table.
--
--   When we run:
--     ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
--   ...only the parent table is tracked. Child partition WAL events are
--   SILENTLY IGNORED by the publication, so Realtime NEVER fires for any
--   new message INSERT, UPDATE, or DELETE.
--
-- Additionally:
--   Without REPLICA IDENTITY FULL on each partition, UPDATE events cannot
--   broadcast the full old/new row — Realtime drops them silently.
--
-- Fix:
--   1. Set REPLICA IDENTITY FULL on every active partition table.
--   2. Add every active partition table individually to supabase_realtime.
--   3. Add a DO block to handle future partitions automatically.
-- ============================================================================

-- ── Step 1: REPLICA IDENTITY FULL on all message partitions ──────────────────

ALTER TABLE public.msg_default   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_02   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_03   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_04   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_05   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_06   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_07   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_08   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_09   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_10   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_11   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2025_12   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_01   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_02   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_03   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_04   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_05   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_06   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_07   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_08   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_09   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_10   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_11   REPLICA IDENTITY FULL;
ALTER TABLE public.msg_2026_12   REPLICA IDENTITY FULL;

-- ── Step 2: Add every partition to the supabase_realtime publication ──────────
-- The parent table entry is kept for compatibility but child partitions must
-- each be added explicitly for WAL events to flow through to Realtime.

ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_default;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_02;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_03;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_04;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_05;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_06;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_07;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_08;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_09;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_10;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_11;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2025_12;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_01;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_02;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_03;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_04;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_05;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_06;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_07;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_08;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_09;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_10;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_11;
ALTER PUBLICATION supabase_realtime ADD TABLE public.msg_2026_12;

-- ── Step 3: Update the partition creation function to auto-register new ones ──
-- Whenever a new monthly partition is created, it must also be:
--   a) Given REPLICA IDENTITY FULL
--   b) Added to supabase_realtime

CREATE OR REPLACE FUNCTION public.create_next_month_partitions()
RETURNS void AS $$
DECLARE
  next_start  DATE := date_trunc('month', now() + interval '1 month');
  next_end    DATE := date_trunc('month', now() + interval '2 months');
  suffix      TEXT := to_char(next_start, 'YYYY_MM');
  tbl_name    TEXT;
BEGIN
  -- ── messages partition ────────────────────────────────────────────────────
  tbl_name := 'msg_' || suffix;
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = tbl_name
  ) THEN
    EXECUTE format(
      'CREATE TABLE public.%I PARTITION OF public.messages FOR VALUES FROM (%L) TO (%L)',
      tbl_name, next_start, next_end
    );
    -- Critical: set REPLICA IDENTITY FULL so UPDATE events broadcast correctly
    EXECUTE format('ALTER TABLE public.%I REPLICA IDENTITY FULL', tbl_name);
    -- Critical: register the new partition with Supabase Realtime
    EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl_name);
    RAISE NOTICE 'Created & registered Realtime partition: %', tbl_name;
  END IF;

  -- ── video_engagement_events partition ─────────────────────────────────────
  tbl_name := 'vee_' || suffix;
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = tbl_name
  ) THEN
    EXECUTE format(
      'CREATE TABLE public.%I PARTITION OF public.video_engagement_events FOR VALUES FROM (%L) TO (%L)',
      tbl_name, next_start, next_end
    );
    RAISE NOTICE 'Created partition: %', tbl_name;
  END IF;

  -- ── feed_impressions partition ─────────────────────────────────────────────
  tbl_name := 'fi_' || suffix;
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = tbl_name
  ) THEN
    EXECUTE format(
      'CREATE TABLE public.%I PARTITION OF public.feed_impressions FOR VALUES FROM (%L) TO (%L)',
      tbl_name, next_start, next_end
    );
    RAISE NOTICE 'Created partition: %', tbl_name;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
