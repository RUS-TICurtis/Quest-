-- Migration: Fix notification trigger — hardcode project URL and anon key
-- The previous trigger relied on custom Postgres settings (app.edge_function_url)
-- that are NOT automatically configured in the remote Supabase project.
-- This version hardcodes the public URL and anon key so the trigger always fires.
-- The anon key is safe to embed — it is already shipped inside the app bundle.

CREATE OR REPLACE FUNCTION public.trigger_process_notification_jobs()
RETURNS TRIGGER AS $$
DECLARE
  edge_url text := 'https://lihaddxlyychswpkswbp.supabase.co/functions/v1';
  anon_key text := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxpaGFkZHhseXljaHN3cGtzd2JwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzNDA5MzQsImV4cCI6MjA4NDkxNjkzNH0.DrBUuz2ayMRCIicYAFNqH2ws3gbRu8ycsbATF54BuFM';
BEGIN
  -- Override with custom settings if configured (for local dev or staging environments)
  IF current_setting('app.edge_function_url', true) IS NOT NULL
     AND current_setting('app.edge_function_url', true) != '' THEN
    edge_url := current_setting('app.edge_function_url', true);
  END IF;

  IF current_setting('app.anon_key', true) IS NOT NULL
     AND current_setting('app.anon_key', true) != '' THEN
    anon_key := current_setting('app.anon_key', true);
  END IF;

  PERFORM net.http_post(
    url     := edge_url || '/process-notification-jobs',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || anon_key
    ),
    body    := '{}'::jsonb,
    timeout_milliseconds := 5000
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
