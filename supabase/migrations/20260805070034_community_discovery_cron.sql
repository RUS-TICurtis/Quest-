-- ============================================================================
-- Community Discovery: pg_cron Scheduled Jobs
-- Schedules the two trending recalculation Edge Functions.
--
-- IMPORTANT: Replace <PROJECT_REF> and <SERVICE_ROLE_KEY> with real values
-- before applying. These are injected as Supabase Vault secrets in production.
-- ============================================================================

-- Every 5 minutes: recalculate community trending scores
SELECT cron.schedule(
  'recalc-community-trending',
  '*/5 * * * *',
  $$
  SELECT
    net.http_post(
      url     := current_setting('app.supabase_url') || '/functions/v1/recalculate-community-trending',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body    := '{}'::jsonb
    )
  $$
);

-- Every 5 minutes: recalculate post trending scores
SELECT cron.schedule(
  'recalc-post-trending',
  '*/5 * * * *',
  $$
  SELECT
    net.http_post(
      url     := current_setting('app.supabase_url') || '/functions/v1/recalculate-post-trending',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      ),
      body    := '{}'::jsonb
    )
  $$
);
