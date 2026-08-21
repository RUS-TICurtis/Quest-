-- ============================================================================
-- SCHEMA GROUP 6: Moderation, Admin & Blocked Content
-- Moderation actions, admin settings, blocked terms, audit RPCs,
-- content-guard triggers, admin dashboard RPCs, creator application RPCs
-- ============================================================================

-- ── Moderation Actions ────────────────────────────────────────────────────────
-- FIX: target_id is nullable; bigint targets (communities) use target_id_int.
-- FIX: target_type check expanded to include 'community'; action list is complete.

CREATE TABLE IF NOT EXISTS public.moderation_actions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id      UUID NOT NULL REFERENCES public.profiles(id),
  target_type   TEXT NOT NULL CHECK (target_type IN (
    'video', 'comment', 'user', 'community_post', 'community', 'chat_message'
  )),
  target_id     UUID,                    -- NULL for BIGINT targets
  target_id_int BIGINT,                 -- for BIGINT targets (communities)
  action        TEXT NOT NULL CHECK (action IN (
    'approve', 'reject', 'remove', 'suppress', 'unsuppress',
    'ban', 'unban', 'suspend', 'unsuspend', 'warn', 'escalate'
  )),
  reason        TEXT,
  metadata      JSONB DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ma_target    ON public.moderation_actions(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_ma_actor     ON public.moderation_actions(actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ma_created   ON public.moderation_actions(created_at DESC);

ALTER TABLE public.moderation_actions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage mod actions" ON public.moderation_actions;
CREATE POLICY "Admins manage mod actions" ON public.moderation_actions FOR ALL USING (public.is_admin_or_reviewer());

-- ── Blocked Terms ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.blocked_terms (
  term       TEXT PRIMARY KEY,
  category   TEXT CHECK (category IN ('hate', 'spam', 'adult', 'violence')),
  severity   TEXT DEFAULT 'high',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.blocked_terms ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage blocked terms" ON public.blocked_terms;
CREATE POLICY "Admins manage blocked terms" ON public.blocked_terms FOR ALL USING (public.is_admin_or_reviewer());

INSERT INTO public.blocked_terms (term, category) VALUES ('spam_link_placeholder', 'spam')
ON CONFLICT DO NOTHING;

-- ── Admin Settings ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_settings (
  key        TEXT PRIMARY KEY,
  value      JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now(),
  updated_by UUID REFERENCES public.profiles(id)
);

ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins manage settings" ON public.admin_settings;
CREATE POLICY "Admins manage settings" ON public.admin_settings FOR ALL USING (public.is_admin_or_reviewer());

INSERT INTO public.admin_settings (key, value) VALUES
  ('maintenance_mode',           'false'::jsonb),
  ('enable_v2_feed',             'true'::jsonb),
  ('max_upload_size_mb',         '100'::jsonb),
  ('auto_moderation_enabled',    'true'::jsonb),
  ('feed_algorithm', '{
    "trending_weight": 0.4,
    "personalized_weight": 0.4,
    "friend_weight": 0.2,
    "ad_frequency": 0.1
  }'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- ── Content Guard Triggers ────────────────────────────────────────────────────
-- Prevents banned/suspended users from posting.

CREATE OR REPLACE FUNCTION public.guard_active_user()
RETURNS TRIGGER AS $$
DECLARE
  v_banned BOOLEAN; v_suspended BOOLEAN;
BEGIN
  SELECT is_banned, is_suspended
  INTO v_banned, v_suspended
  FROM public.profiles WHERE id = auth.uid();

  IF v_banned    THEN RAISE EXCEPTION 'Account is banned'; END IF;
  IF v_suspended THEN RAISE EXCEPTION 'Account is suspended'; END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS guard_posts    ON public.community_posts;
CREATE TRIGGER guard_posts    BEFORE INSERT ON public.community_posts    FOR EACH ROW EXECUTE FUNCTION public.guard_active_user();

DROP TRIGGER IF EXISTS guard_comments ON public.community_comments;
CREATE TRIGGER guard_comments BEFORE INSERT ON public.community_comments FOR EACH ROW EXECUTE FUNCTION public.guard_active_user();

DROP TRIGGER IF EXISTS guard_vc       ON public.video_comments;
CREATE TRIGGER guard_vc       BEFORE INSERT ON public.video_comments     FOR EACH ROW EXECUTE FUNCTION public.guard_active_user();

DROP TRIGGER IF EXISTS guard_react    ON public.video_reactions;
CREATE TRIGGER guard_react    BEFORE INSERT ON public.video_reactions    FOR EACH ROW EXECUTE FUNCTION public.guard_active_user();

DROP TRIGGER IF EXISTS guard_msg      ON public.messages;
CREATE TRIGGER guard_msg      BEFORE INSERT ON public.messages           FOR EACH ROW EXECUTE FUNCTION public.guard_active_user();

-- Blocked-terms filter (PostgreSQL whole-word regex)
CREATE OR REPLACE FUNCTION public.check_blocked_terms()
RETURNS TRIGGER AS $$
DECLARE v_term TEXT;
BEGIN
  IF NEW.content IS NOT NULL THEN
    FOR v_term IN SELECT term FROM public.blocked_terms WHERE category IN ('hate', 'spam', 'violence') LOOP
      IF NEW.content ~* ('\m' || v_term || '\M') THEN
        RAISE EXCEPTION 'Content violates community guidelines: contains blocked term.';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_check_blocked_terms_msg     ON public.messages;
DROP TRIGGER IF EXISTS trigger_check_blocked_terms_post    ON public.community_posts;
DROP TRIGGER IF EXISTS trigger_check_blocked_terms_comment ON public.community_comments;
CREATE TRIGGER trigger_check_blocked_terms_msg
  BEFORE INSERT OR UPDATE ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.check_blocked_terms();
CREATE TRIGGER trigger_check_blocked_terms_post
  BEFORE INSERT OR UPDATE ON public.community_posts
  FOR EACH ROW EXECUTE FUNCTION public.check_blocked_terms();
CREATE TRIGGER trigger_check_blocked_terms_comment
  BEFORE INSERT OR UPDATE ON public.community_comments
  FOR EACH ROW EXECUTE FUNCTION public.check_blocked_terms();

-- Auto-hide highly-reported content
CREATE OR REPLACE FUNCTION public.auto_hide_reported_content()
RETURNS TRIGGER AS $$
DECLARE
  v_report_count INT;
  v_hide_threshold INT := 3;
BEGIN
  SELECT COUNT(*) INTO v_report_count
  FROM public.reports
  WHERE target_id = NEW.target_id AND status = 'pending';

  IF v_report_count >= v_hide_threshold THEN
    IF NEW.target_type = 'chat_message' THEN
      UPDATE public.messages
      SET content = 'This message was hidden due to multiple reports.' WHERE id = NEW.target_id::uuid;
    ELSIF NEW.target_type = 'community_post' THEN
      UPDATE public.community_posts SET is_hidden = true WHERE id = NEW.target_id::uuid;
    ELSIF NEW.target_type = 'community_comment' THEN
      UPDATE public.community_comments
      SET content = 'This comment was hidden due to multiple reports.' WHERE id = NEW.target_id::uuid;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_auto_hide_reported_content ON public.reports;
CREATE TRIGGER trigger_auto_hide_reported_content
  AFTER INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.auto_hide_reported_content();

-- ── Admin RPCs ────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_dau INT; v_new_users INT; v_uploads INT; v_pending_reports INT;
BEGIN
  SELECT COUNT(DISTINCT user_id)     INTO v_dau            FROM public.user_daily_stats WHERE date = CURRENT_DATE;
  SELECT COUNT(*)                    INTO v_new_users       FROM public.profiles         WHERE created_at::date = CURRENT_DATE;
  SELECT COUNT(*)                    INTO v_uploads         FROM public.creator_videos   WHERE created_at::date = CURRENT_DATE;
  SELECT COUNT(*)                    INTO v_pending_reports FROM public.reports          WHERE status = 'pending';

  RETURN jsonb_build_object(
    'daily_active_users', COALESCE(v_dau, 0),
    'new_users_today',    COALESCE(v_new_users, 0),
    'videos_uploaded_today', COALESCE(v_uploads, 0),
    'pending_reports',    COALESCE(v_pending_reports, 0)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_admin_users(
  p_page   INT  DEFAULT 1,
  p_limit  INT  DEFAULT 20,
  p_search TEXT DEFAULT ''
) RETURNS TABLE (
  id           UUID,
  username     TEXT,
  email        VARCHAR(255),
  role         TEXT,
  status       TEXT,
  avatar_url   TEXT,
  created_at   TIMESTAMPTZ,
  report_count BIGINT
) AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role IN ('admin', 'reviewer')) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- FIX: wrap in subquery to avoid PL/pgSQL column name ambiguity between
  -- the RETURNS TABLE variable `id` and the table column `p.id`
  RETURN QUERY
  SELECT
    sub.id,
    sub.username,
    sub.email,
    sub.role,
    sub.status,
    sub.avatar_url,
    sub.created_at,
    sub.report_count
  FROM (
    SELECT
      p.id                     AS id,
      p.username               AS username,
      au.email::VARCHAR(255)   AS email,
      p.role                   AS role,
      CASE
        WHEN p.is_banned       THEN 'Banned'
        WHEN p.is_suspended    THEN 'Suspended'
        WHEN p.is_shadowbanned THEN 'Shadowbanned'
        ELSE 'Active'
      END                      AS status,
      p.avatar_url             AS avatar_url,
      p.created_at             AS created_at,
      (SELECT COUNT(*)
         FROM public.reports r
        WHERE r.reported_user_id = p.id
      )::BIGINT                AS report_count
    FROM public.profiles p
    JOIN auth.users au ON au.id = p.id
    WHERE (
      p_search = ''
      OR p.username ILIKE '%' || p_search || '%'
      OR au.email  ILIKE '%' || p_search || '%'
    )
    ORDER BY p.created_at DESC
    LIMIT  p_limit
    OFFSET (p_page - 1) * p_limit
  ) sub;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
CREATE OR REPLACE FUNCTION public.approve_creator_application(p_app_id UUID)
RETURNS VOID AS $$
DECLARE v_user_id UUID;
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT user_id INTO v_user_id FROM public.creator_applications WHERE id = p_app_id;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Application not found'; END IF;

  UPDATE public.creator_applications
  SET status = 'approved', reviewed_by = auth.uid(), reviewed_at = now()
  WHERE id = p_app_id;

  UPDATE public.profiles
  SET role = 'creator', creator_status = 'approved', creator_verified_at = now()
  WHERE id = v_user_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), 'user', v_user_id, 'approve', 'Application Approved');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.reject_creator_application(p_app_id UUID, p_reason TEXT)
RETURNS VOID AS $$
DECLARE v_user_id UUID;
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  SELECT user_id INTO v_user_id FROM public.creator_applications WHERE id = p_app_id;
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Application not found'; END IF;

  UPDATE public.creator_applications
  SET status = 'rejected', reviewed_by = auth.uid(), review_notes = p_reason, reviewed_at = now()
  WHERE id = p_app_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), 'user', v_user_id, 'reject', p_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.freeze_community(p_community_id BIGINT, p_reason TEXT)
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE public.communities SET status = 'suspended' WHERE id = p_community_id;

  -- FIX: communities have BIGINT id; use target_id_int, leave target_id NULL
  INSERT INTO public.moderation_actions (actor_id, target_type, target_id_int, action, reason)
  VALUES (auth.uid(), 'community', p_community_id, 'suspend', p_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.resolve_report(
  p_report_id UUID,
  p_action    TEXT,
  p_notes     TEXT
) RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;
  UPDATE public.reports
  SET status = p_action, reviewed_by = auth.uid(), review_notes = p_notes, updated_at = now()
  WHERE id = p_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
