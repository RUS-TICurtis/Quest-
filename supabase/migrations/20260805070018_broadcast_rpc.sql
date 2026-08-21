-- RPC to fan out a notification to all active users
CREATE OR REPLACE FUNCTION public.send_global_notification(
  p_title TEXT,
  p_body TEXT,
  p_type TEXT DEFAULT 'announcement',
  p_image_url TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  -- 1. Insert into history table for all users
  INSERT INTO public.notifications (user_id, title, body, type, image_url, metadata)
  SELECT id, p_title, p_body, p_type, p_image_url, p_metadata
  FROM public.profiles
  WHERE is_banned = false;

  -- 2. Log the administrative action
  INSERT INTO public.moderation_actions (actor_id, target_type, action, reason, metadata)
  VALUES (
    auth.uid(), 
    'system', 
    'broadcast', 
    p_title, 
    jsonb_build_object('body', p_body, 'type', p_type)
  );

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: The actual FCM push delivery should be handled by a Database Webhook 
-- triggering an Edge Function that listens for these inserts or by the Admin 
-- Dashboard calling the Edge Function directly.
