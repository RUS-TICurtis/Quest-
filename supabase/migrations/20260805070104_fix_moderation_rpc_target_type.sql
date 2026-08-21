-- Fix target_type mapping for admin_delete_content and admin_hide_content

CREATE OR REPLACE FUNCTION public.admin_delete_content(
  p_target_type TEXT, p_target_id TEXT, p_reason TEXT
) RETURNS VOID AS $$
DECLARE v_log_target_type TEXT;
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  v_log_target_type := CASE
    WHEN p_target_type = 'creator_video' THEN 'video'
    WHEN p_target_type = 'community_comment' THEN 'comment'
    ELSE p_target_type
  END;

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
  VALUES (auth.uid(), v_log_target_type, p_target_id::UUID, 'remove', p_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_hide_content(
  p_target_type TEXT, p_target_id TEXT, p_hide BOOLEAN
) RETURNS VOID AS $$
DECLARE v_log_target_type TEXT;
BEGIN
  IF NOT public.is_admin_or_reviewer() THEN RAISE EXCEPTION 'Unauthorized'; END IF;

  v_log_target_type := CASE
    WHEN p_target_type = 'creator_video' THEN 'video'
    WHEN p_target_type = 'community_comment' THEN 'comment'
    ELSE p_target_type
  END;

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
  VALUES (auth.uid(), v_log_target_type, p_target_id::UUID,
          CASE WHEN p_hide THEN 'suppress' ELSE 'unsuppress' END,
          'Admin hide/unhide action');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
