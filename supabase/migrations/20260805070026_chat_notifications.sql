-- Migration: Add push notification triggers for DMs and Group Chats

-- Create a function to queue a notification job when a new message is inserted
CREATE OR REPLACE FUNCTION public.trigger_chat_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_is_group BOOLEAN;
  v_group_name TEXT;
  v_sender_name TEXT;
BEGIN
  -- Skip if there's no content or it's a system message that shouldn't notify (if applicable)
  -- Get chat details
  SELECT is_group, group_name INTO v_is_group, v_group_name
  FROM public.chats WHERE id = NEW.chat_id;

  -- Get sender name (prefer first_name, fallback to username)
  SELECT COALESCE(NULLIF(trim(first_name), ''), username) INTO v_sender_name
  FROM public.profiles WHERE id = NEW.sender_id;

  -- Insert into notification_jobs
  INSERT INTO public.notification_jobs (type, payload)
  VALUES (
    'chat_message',
    jsonb_build_object(
      'message_id', NEW.id,
      'chat_id', NEW.chat_id,
      'sender_id', NEW.sender_id,
      'sender_name', COALESCE(v_sender_name, 'Someone'),
      'is_group', v_is_group,
      'group_name', v_group_name,
      'content', NEW.content,
      'message_type', NEW.type
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add trigger to messages table
DROP TRIGGER IF EXISTS trigger_queue_chat_notification ON public.messages;
CREATE TRIGGER trigger_queue_chat_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.trigger_chat_notification();
