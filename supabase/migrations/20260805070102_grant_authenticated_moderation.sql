-- Create RPC for ban_user
CREATE OR REPLACE FUNCTION public.ban_user(p_user_id UUID, p_reason TEXT)
RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.profiles
  SET is_banned = true, ban_reason = p_reason
  WHERE id = p_user_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), 'user', p_user_id, 'ban', p_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create RPC for unban_user
CREATE OR REPLACE FUNCTION public.unban_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.profiles
  SET is_banned = false, ban_reason = NULL
  WHERE id = p_user_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), 'user', p_user_id, 'unban', 'Admin unban action');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execution to service_role and authenticated roles for all moderation RPCs
GRANT EXECUTE ON FUNCTION public.warn_user(UUID, TEXT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.suspend_user(UUID, TEXT, INT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_content(TEXT, TEXT, TEXT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_hide_content(TEXT, TEXT, BOOLEAN) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.flag_reporter(UUID, TEXT, INT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_content_context(TEXT, TEXT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.ban_user(UUID, TEXT) TO service_role, authenticated;
GRANT EXECUTE ON FUNCTION public.unban_user(UUID) TO service_role, authenticated;
