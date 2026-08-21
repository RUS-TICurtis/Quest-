-- Create RPC for unsuspend_user
CREATE OR REPLACE FUNCTION public.unsuspend_user(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.profiles
  SET is_suspended = false, suspended_until = NULL
  WHERE id = p_user_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), 'user', p_user_id, 'unsuspend', 'Admin unsuspend action');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.unsuspend_user(UUID) TO service_role, authenticated;
