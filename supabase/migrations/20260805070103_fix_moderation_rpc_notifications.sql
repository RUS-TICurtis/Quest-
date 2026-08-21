-- Fix warn_user to use correct notification_jobs columns
CREATE OR REPLACE FUNCTION public.warn_user(p_user_id UUID, p_reason TEXT)
RETURNS VOID AS $$
DECLARE v_strikes INT;
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.profiles
  SET strikes = strikes + 1, last_warned_at = now()
  WHERE id = p_user_id
  RETURNING strikes INTO v_strikes;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), 'user', p_user_id, 'warn', p_reason);

  -- Auto-suspend after 3 strikes (7 days)
  IF v_strikes >= 3 THEN
    UPDATE public.profiles
    SET is_suspended = true,
        suspended_until = now() + interval '7 days'
    WHERE id = p_user_id;

    INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
    VALUES (auth.uid(), 'user', p_user_id, 'suspend', 'Auto-suspended after 3 strikes');
  END IF;

  -- Trigger in-app notification
  INSERT INTO public.notification_jobs (type, payload)
  VALUES (
    'moderation_warning',
    jsonb_build_object(
      'user_id', p_user_id,
      'title', 'Warning from Finishd',
      'body', p_reason,
      'data', jsonb_build_object('type', 'moderation_warning')
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix suspend_user to use correct notification_jobs columns
CREATE OR REPLACE FUNCTION public.suspend_user(p_user_id UUID, p_reason TEXT, p_duration_hours INT)
RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.profiles
  SET is_suspended = true,
      suspended_until = now() + (p_duration_hours || ' hours')::INTERVAL
  WHERE id = p_user_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), 'user', p_user_id, 'suspend', p_reason);

  INSERT INTO public.notification_jobs (type, payload)
  VALUES (
    'moderation_suspension',
    jsonb_build_object(
      'user_id', p_user_id,
      'title', 'Account Suspended',
      'body', 'Your account has been suspended for ' || p_duration_hours || ' hours. Reason: ' || p_reason,
      'data', jsonb_build_object('type', 'moderation_suspension')
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
