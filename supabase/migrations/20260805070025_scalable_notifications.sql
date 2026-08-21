-- Migration: Scalable Notifications Architecture
-- Create notification_jobs table for async processing and enforce idempotency

CREATE TABLE IF NOT EXISTS public.notification_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  payload JSONB NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  retry_count INT DEFAULT 0,
  scheduled_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_jobs_status_scheduled ON public.notification_jobs(status, scheduled_at);

-- Add unique constraint to enforce idempotency on notifications
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'idx_unique_user_reference_type'
  ) THEN
    -- First, remove any existing duplicates, keeping the most recent one
    DELETE FROM public.notifications a
    USING public.notifications b
    WHERE a.user_id = b.user_id 
      AND a.type = b.type 
      AND a.reference_id = b.reference_id 
      AND (a.created_at < b.created_at OR (a.created_at = b.created_at AND a.id < b.id));

    -- Now safely add the constraint
    ALTER TABLE public.notifications ADD CONSTRAINT idx_unique_user_reference_type UNIQUE (user_id, reference_id, type);
  END IF;
END $$;

-- Triggers for notification_jobs updated_at
CREATE OR REPLACE FUNCTION public.sync_notification_jobs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_notification_jobs_updated_at ON public.notification_jobs;
CREATE TRIGGER trg_notification_jobs_updated_at
  BEFORE UPDATE ON public.notification_jobs
  FOR EACH ROW EXECUTE FUNCTION public.sync_notification_jobs_updated_at();

-- RLS for notification_jobs (internal table, deny all to anon/authenticated, allow service role)
ALTER TABLE public.notification_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service Role full access on notification_jobs" ON public.notification_jobs;
CREATE POLICY "Service Role full access on notification_jobs"
  ON public.notification_jobs
  FOR ALL TO service_role
  USING (true)
  WITH CHECK (true);


-- Ensure community members are accessible but secure
-- The existing policy allows public read. That's usually fine for the app,
-- but if we want to restrict it strictly to members:
-- DROP POLICY IF EXISTS "Public read members" ON public.community_members;
-- CREATE POLICY "Users read community members if joined" ON public.community_members FOR SELECT USING (
--   community_id IN (SELECT community_id FROM public.community_members WHERE user_id = auth.uid()) OR auth.role() = 'service_role'
-- );
-- Note: Leaving Public read for now as the app might depend on it for discovery.


-- RPC to atomically claim notification jobs using FOR UPDATE SKIP LOCKED
CREATE OR REPLACE FUNCTION public.claim_notification_jobs(p_limit INT DEFAULT 50)
RETURNS SETOF public.notification_jobs AS $$
DECLARE
  claimed_ids UUID[];
BEGIN
  -- 1. Select and lock pending jobs safely
  SELECT array_agg(id) INTO claimed_ids
  FROM (
    SELECT id
    FROM public.notification_jobs
    WHERE status = 'pending'
      AND scheduled_at <= now()
    ORDER BY created_at ASC
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  ) as locked_jobs;

  IF claimed_ids IS NULL THEN
    RETURN;
  END IF;

  -- 2. Mark them as processing and return the rows
  RETURN QUERY
  UPDATE public.notification_jobs
  SET status = 'processing', updated_at = now()
  WHERE id = ANY(claimed_ids)
  RETURNING *;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Optional Rate Limiting helper. Count notifications sent to a topic/community in the last hour
CREATE OR REPLACE FUNCTION public.check_community_notification_rate_limit(p_community_id BIGINT, p_limit INT)
RETURNS BOOLEAN AS $$
DECLARE
  v_count INT;
BEGIN
  -- We count by looking at jobs that were successfully processed recently
  SELECT count(*) INTO v_count
  FROM public.notification_jobs
  WHERE status = 'completed'
    AND payload->>'community_id' = p_community_id::text
    AND created_at >= now() - interval '1 hour';

  RETURN v_count < p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
