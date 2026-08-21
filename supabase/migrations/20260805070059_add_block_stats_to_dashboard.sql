-- ── Add Block Stats to Dashboard ──────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_admin_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_dau INT; v_new_users INT; v_uploads INT; v_pending_reports INT; v_blocks INT;
BEGIN
  SELECT COUNT(DISTINCT user_id)     INTO v_dau            FROM public.user_daily_stats WHERE date = CURRENT_DATE;
  SELECT COUNT(*)                    INTO v_new_users       FROM public.profiles         WHERE created_at::date = CURRENT_DATE;
  SELECT COUNT(*)                    INTO v_uploads         FROM public.creator_videos   WHERE created_at::date = CURRENT_DATE;
  SELECT COUNT(*)                    INTO v_pending_reports FROM public.reports          WHERE status = 'pending';
  SELECT COUNT(*)                    INTO v_blocks          FROM public.user_blocks;

  RETURN jsonb_build_object(
    'daily_active_users', COALESCE(v_dau, 0),
    'new_users_today',    COALESCE(v_new_users, 0),
    'videos_uploaded_today', COALESCE(v_uploads, 0),
    'pending_reports',    COALESCE(v_pending_reports, 0),
    'total_blocks',       COALESCE(v_blocks, 0)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
