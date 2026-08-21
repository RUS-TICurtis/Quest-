-- Add strikes counter and last_warned_at to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS strikes         INT     NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_warned_at  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS suspended_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reporter_flagged_until TIMESTAMPTZ;

-- RPC: warn_user
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
  INSERT INTO public.notification_jobs (user_id, title, body, data)
  VALUES (p_user_id, 'Warning from Finishd', p_reason,
          jsonb_build_object('type', 'moderation_warning'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update guard trigger
CREATE OR REPLACE FUNCTION public.guard_active_user()
RETURNS TRIGGER AS $$
DECLARE v_banned BOOLEAN; v_suspended BOOLEAN; v_suspended_until TIMESTAMPTZ;
BEGIN
  SELECT is_banned, is_suspended, suspended_until
  INTO v_banned, v_suspended, v_suspended_until
  FROM public.profiles WHERE id = auth.uid();

  IF v_banned THEN RAISE EXCEPTION 'Account is banned'; END IF;
  
  IF v_suspended AND (v_suspended_until IS NULL OR v_suspended_until > now()) THEN
    RAISE EXCEPTION 'Account is suspended';
  ELSIF v_suspended AND v_suspended_until <= now() THEN
    UPDATE public.profiles SET is_suspended = false, suspended_until = NULL WHERE id = auth.uid();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: suspend_user
CREATE OR REPLACE FUNCTION public.suspend_user(
  p_user_id UUID, p_reason TEXT, p_duration_hours INT
) RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.profiles
  SET is_suspended = true,
      suspended_until = now() + (p_duration_hours || ' hours')::INTERVAL
  WHERE id = p_user_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason, metadata)
  VALUES (auth.uid(), 'user', p_user_id, 'suspend', p_reason,
          jsonb_build_object('duration_hours', p_duration_hours,
                             'expires_at', (now() + (p_duration_hours || ' hours')::INTERVAL)));

  INSERT INTO public.notification_jobs (user_id, title, body, data)
  VALUES (p_user_id, 'Account Suspended',
          'Your account has been suspended for ' || p_duration_hours || ' hours. Reason: ' || p_reason,
          jsonb_build_object('type', 'moderation_suspension'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: admin_delete_content
CREATE OR REPLACE FUNCTION public.admin_delete_content(
  p_target_type TEXT, p_target_id TEXT, p_reason TEXT
) RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  IF p_target_type = 'community_post' THEN
    DELETE FROM public.community_posts WHERE id = p_target_id::UUID;
  ELSIF p_target_type = 'community_comment' THEN
    DELETE FROM public.community_comments WHERE id = p_target_id::UUID;
  ELSIF p_target_type = 'chat_message' THEN
    DELETE FROM public.messages WHERE id = p_target_id::UUID;
  ELSIF p_target_type = 'creator_video' THEN
    UPDATE public.creator_videos
    SET status = 'removed', deleted_at = now()
    WHERE id = p_target_id::UUID;
  ELSE
    RAISE EXCEPTION 'Unknown target_type: %', p_target_type;
  END IF;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), p_target_type, p_target_id::UUID, 'remove', p_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: admin_hide_content
CREATE OR REPLACE FUNCTION public.admin_hide_content(
  p_target_type TEXT, p_target_id TEXT, p_hide BOOLEAN
) RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  IF p_target_type = 'community_post' THEN
    UPDATE public.community_posts
    SET is_hidden = p_hide, deleted_at = CASE WHEN p_hide THEN now() ELSE NULL END
    WHERE id = p_target_id::UUID;
  ELSIF p_target_type = 'community_comment' THEN
    UPDATE public.community_comments
    SET deleted_at = CASE WHEN p_hide THEN now() ELSE NULL END
    WHERE id = p_target_id::UUID;
  ELSIF p_target_type = 'creator_video' THEN
    UPDATE public.creator_videos
    SET status = CASE WHEN p_hide THEN 'removed' ELSE 'approved' END
    WHERE id = p_target_id::UUID;
  END IF;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason)
  VALUES (auth.uid(), p_target_type, p_target_id::UUID,
          CASE WHEN p_hide THEN 'suppress' ELSE 'unsuppress' END,
          'Admin hide/unhide action');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update report rate-limit trigger
CREATE OR REPLACE FUNCTION public.check_report_rate_limit()
RETURNS TRIGGER AS $$
DECLARE v_report_count INT; v_flagged_until TIMESTAMPTZ;
BEGIN
  SELECT reporter_flagged_until INTO v_flagged_until
  FROM public.profiles WHERE id = NEW.reporter_id;

  IF v_flagged_until IS NOT NULL AND v_flagged_until > now() THEN
    RAISE EXCEPTION 'Your ability to submit reports has been temporarily restricted.';
  END IF;

  SELECT COUNT(*) INTO v_report_count
  FROM public.reports
  WHERE reporter_id = NEW.reporter_id AND created_at > now() - interval '1 minute';

  IF v_report_count >= 5 THEN
    RAISE EXCEPTION 'Rate limit exceeded: max 5 reports per minute.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: flag_reporter
CREATE OR REPLACE FUNCTION public.flag_reporter(
  p_reporter_id UUID, p_reason TEXT, p_duration_hours INT DEFAULT 24
) RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  UPDATE public.profiles
  SET reporter_flagged_until = now() + (p_duration_hours || ' hours')::INTERVAL
  WHERE id = p_reporter_id;

  INSERT INTO public.moderation_actions (actor_id, target_type, target_id, action, reason, metadata)
  VALUES (auth.uid(), 'user', p_reporter_id, 'escalate', p_reason,
          jsonb_build_object('type', 'reporter_flagged', 'duration_hours', p_duration_hours));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: admin_get_content_context
CREATE OR REPLACE FUNCTION public.admin_get_content_context(
  p_target_type TEXT, p_target_id TEXT
) RETURNS JSONB AS $$
DECLARE v_result JSONB;
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  IF p_target_type = 'community_post' THEN
    SELECT row_to_json(t)::JSONB INTO v_result
    FROM (
      SELECT cp.*, p.username AS author_username
      FROM public.community_posts cp
      JOIN public.profiles p ON p.id = cp.author_id
      WHERE cp.id = p_target_id::UUID
    ) t;
  ELSIF p_target_type = 'community_comment' THEN
    SELECT jsonb_build_object(
      'comment', row_to_json(c),
      'post', row_to_json(cp)
    ) INTO v_result
    FROM public.community_comments c
    JOIN public.community_posts cp ON cp.id = c.post_id
    WHERE c.id = p_target_id::UUID;
  ELSIF p_target_type = 'chat_message' THEN
    SELECT jsonb_agg(row_to_json(m) ORDER BY m.created_at) INTO v_result
    FROM public.messages m
    WHERE m.chat_id = (
      SELECT chat_id FROM public.messages WHERE id = p_target_id::UUID
    )
    AND m.created_at BETWEEN
      (SELECT created_at - interval '15 minutes' FROM public.messages WHERE id = p_target_id::UUID)
      AND
      (SELECT created_at + interval '5 minutes' FROM public.messages WHERE id = p_target_id::UUID);
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.warn_user(UUID, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.suspend_user(UUID, TEXT, INT) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_delete_content(TEXT, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_hide_content(TEXT, TEXT, BOOLEAN) TO service_role;
GRANT EXECUTE ON FUNCTION public.flag_reporter(UUID, TEXT, INT) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_get_content_context(TEXT, TEXT) TO service_role;
