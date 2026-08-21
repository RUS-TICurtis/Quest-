-- Migration: Add push notification triggers for Moderation actions (bans, suspensions)

-- Create a function to queue a notification job when a user is banned or suspended
CREATE OR REPLACE FUNCTION public.trigger_moderation_push_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- We only care about bans or suspends targeting a user
  IF NEW.target_type = 'user' AND NEW.action IN ('ban', 'suspend') THEN
    INSERT INTO public.notification_jobs (type, payload)
    VALUES (
      'moderation_action',
      jsonb_build_object(
        'user_id', NEW.target_id,
        'action', NEW.action,
        'reason', NEW.reason,
        'moderation_id', NEW.id
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add trigger to moderation_actions table
DROP TRIGGER IF EXISTS queue_moderation_push ON public.moderation_actions;
CREATE TRIGGER queue_moderation_push
  AFTER INSERT ON public.moderation_actions
  FOR EACH ROW EXECUTE FUNCTION public.trigger_moderation_push_notification();
