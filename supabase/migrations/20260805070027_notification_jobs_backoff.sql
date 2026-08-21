-- Migration: Add next_retry_at column to notification_jobs for exponential back-off.
--
-- Why: Before this migration, failed notification jobs were immediately re-queued
-- as 'pending', causing tight retry loops that could hammer FCM and Supabase.
-- The process-notification-jobs Edge Function now sets next_retry_at using:
--   2^retry_count minutes  (2m → 4m → 8m)
--
-- The claim_notification_jobs RPC is updated to skip jobs whose next_retry_at
-- is in the future.

-- 1. Add the column (idempotent)
ALTER TABLE public.notification_jobs
  ADD COLUMN IF NOT EXISTS next_retry_at TIMESTAMPTZ DEFAULT NULL;

-- 2. Add an index so the WHERE clause in the RPC hits the index, not a full scan.
CREATE INDEX IF NOT EXISTS idx_notification_jobs_retry
  ON public.notification_jobs (status, next_retry_at, created_at);

-- 3. Update the claim_notification_jobs RPC to honour next_retry_at.
CREATE OR REPLACE FUNCTION public.claim_notification_jobs(p_limit INT DEFAULT 50)
RETURNS SETOF public.notification_jobs AS $$
DECLARE
  claimed_ids UUID[];
BEGIN
  -- 1. Select and lock pending jobs that are ready to be processed.
  --    A job is "ready" when:
  --      - next_retry_at IS NULL  (never retried, or just created)
  --      - OR next_retry_at <= now()  (back-off window has elapsed)
  SELECT array_agg(id) INTO claimed_ids
  FROM (
    SELECT id
    FROM public.notification_jobs
    WHERE status = 'pending'
      AND scheduled_at <= now()
      AND (next_retry_at IS NULL OR next_retry_at <= now())
    ORDER BY created_at ASC
    LIMIT p_limit
    FOR UPDATE SKIP LOCKED
  ) AS locked_jobs;

  IF claimed_ids IS NULL THEN
    RETURN;
  END IF;

  -- 2. Mark them as processing and return the rows.
  RETURN QUERY
  UPDATE public.notification_jobs
  SET status = 'processing', updated_at = now()
  WHERE id = ANY(claimed_ids)
  RETURNING *;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
