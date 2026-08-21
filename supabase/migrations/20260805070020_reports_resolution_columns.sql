-- Add resolution tracking columns for admin moderation workflow
ALTER TABLE public.reports
  ADD COLUMN IF NOT EXISTS resolution_notes TEXT,
  ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;

-- Prevent the same user from submitting duplicate reports on the same content
ALTER TABLE public.reports
  DROP CONSTRAINT IF EXISTS reports_unique_reporter_target;

ALTER TABLE public.reports
  ADD CONSTRAINT reports_unique_reporter_target
  UNIQUE (reporter_id, target_id, target_type);

-- Performance indexes for admin queue
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_target_type ON public.reports(target_type);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);
