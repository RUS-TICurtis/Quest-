-- Ensure pg_cron is enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule the story-cleanup Edge Function to run every hour
SELECT cron.schedule(
    'invoke-story-cleanup',
    '0 * * * *', -- Every hour, on the hour
    $$
    SELECT net.http_post(
        url:='https://ipvsbunseucoheycxpeg.supabase.co/functions/v1/story-cleanup',
        headers:='{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('request.jwt.claim.role', true) || '"}'::jsonb
    );
    $$
);
