-- Migration for Email Center & Admin Alerts

-- 1. Create Enums
DO $$ BEGIN
    CREATE TYPE email_status AS ENUM ('pending', 'processing', 'sent', 'failed', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Email Templates
CREATE TABLE IF NOT EXISTS email_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    subject TEXT NOT NULL,
    html_body TEXT NOT NULL,
    variables TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Email Queue
CREATE TABLE IF NOT EXISTS email_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payload JSONB NOT NULL, -- { to, subject, html_body, template_id, variables }
    priority INT DEFAULT 0,
    status email_status DEFAULT 'pending',
    retry_count INT DEFAULT 0,
    scheduled_for TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Email Logs
CREATE TABLE IF NOT EXISTS email_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient TEXT NOT NULL,
    subject TEXT NOT NULL,
    template_id UUID REFERENCES email_templates(id) ON DELETE SET NULL,
    status email_status DEFAULT 'sent',
    provider_message_id TEXT,
    sent_by_admin UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Admin Notifications
CREATE TABLE IF NOT EXISTS admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL, -- 'report', 'system', 'moderation'
    payload JSONB,
    priority INT DEFAULT 0,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Email Preferences
CREATE TABLE IF NOT EXISTS email_preferences (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    marketing BOOLEAN DEFAULT TRUE,
    announcements BOOLEAN DEFAULT TRUE,
    moderation BOOLEAN DEFAULT TRUE,
    security BOOLEAN DEFAULT TRUE,
    digest BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. RLS Policies
-- Only allow admin users (users with role 'admin' in profiles or custom claims, here we assume checking profiles role='admin')
-- Since Admin uses SupabaseService, let's create a helper function to check admin status
CREATE OR REPLACE FUNCTION is_admin() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_preferences ENABLE ROW LEVEL SECURITY;

-- Policies for Admins (Full Access)
CREATE POLICY "Admin full access on email_templates" ON email_templates FOR ALL USING (is_admin());
CREATE POLICY "Admin full access on email_queue" ON email_queue FOR ALL USING (is_admin());
CREATE POLICY "Admin full access on email_logs" ON email_logs FOR ALL USING (is_admin());
CREATE POLICY "Admin full access on admin_notifications" ON admin_notifications FOR ALL USING (is_admin());

-- Users can manage their own email preferences
CREATE POLICY "Users manage own email_preferences" ON email_preferences FOR ALL USING (auth.uid() = user_id);
-- Admins can read all preferences
CREATE POLICY "Admin read email_preferences" ON email_preferences FOR SELECT USING (is_admin());

-- 8. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_email_queue_status_sched ON email_queue(status, scheduled_for);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_unread ON admin_notifications(is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_email_logs_created ON email_logs(created_at DESC);

-- 9. Realtime integration for Admin Notifications
ALTER PUBLICATION supabase_realtime ADD TABLE admin_notifications;

-- 10. RPC to claim email jobs safely (atomic)
CREATE OR REPLACE FUNCTION claim_email_jobs(p_limit INT)
RETURNS SETOF email_queue AS $$
DECLARE
    job_record email_queue%ROWTYPE;
BEGIN
    FOR job_record IN 
        SELECT * FROM email_queue 
        WHERE status = 'pending' AND scheduled_for <= NOW()
        ORDER BY priority DESC, scheduled_for ASC
        FOR UPDATE SKIP LOCKED
        LIMIT p_limit
    LOOP
        UPDATE email_queue 
        SET status = 'processing' 
        WHERE id = job_record.id 
        RETURNING * INTO job_record;
        
        RETURN NEXT job_record;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Trigger to create admin alert when a report is inserted
CREATE OR REPLACE FUNCTION trigger_admin_alert_on_report()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO admin_notifications (type, payload, priority)
    VALUES (
        'report',
        jsonb_build_object(
            'report_id', NEW.id,
            'target_type', NEW.target_type,
            'target_id', NEW.target_id,
            'reporter_id', NEW.reporter_id,
            'reason', NEW.reason
        ),
        1 -- High priority
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Assuming table `reports` exists. If not, it will fail, so we wrap it in a DO block checking existence
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reports') THEN
        DROP TRIGGER IF EXISTS on_report_created_alert_admin ON reports;
        CREATE TRIGGER on_report_created_alert_admin
        AFTER INSERT ON reports
        FOR EACH ROW
        EXECUTE FUNCTION trigger_admin_alert_on_report();
    END IF;
END $$;
