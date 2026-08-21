-- Migration: Trigger Edge Function on new Notification Jobs
-- Automatically triggers the process-notification-jobs edge function when a job is inserted

CREATE OR REPLACE FUNCTION public.trigger_process_notification_jobs()
RETURNS TRIGGER AS $$
DECLARE
  edge_url text;
BEGIN
  edge_url := current_setting('app.edge_function_url', true);
  
  -- Only perform the HTTP post if the edge function URL is configured
  IF edge_url IS NOT NULL AND edge_url != '' THEN
    PERFORM net.http_post(
      url     := edge_url || '/process-notification-jobs',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.anon_key', true)
      ),
      body    := jsonb_build_object()
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add statement-level trigger so bulk inserts only fire one webhook
DROP TRIGGER IF EXISTS trg_process_notification_jobs ON public.notification_jobs;
CREATE TRIGGER trg_process_notification_jobs
  AFTER INSERT ON public.notification_jobs
  FOR EACH STATEMENT EXECUTE FUNCTION public.trigger_process_notification_jobs();

-- Add a fallback cron job to run every 5 minutes to process retries and missed jobs
DO $migration$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('process_notification_jobs_sweep');
    
    PERFORM cron.schedule(
      'process_notification_jobs_sweep',
      '*/5 * * * *',
      $$
      SELECT net.http_post(
        url := current_setting('app.edge_function_url', true) || '/process-notification-jobs',
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || current_setting('app.anon_key', true)
        )
      );
      $$
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Fallback if permission issues or missing extension
END $migration$;
