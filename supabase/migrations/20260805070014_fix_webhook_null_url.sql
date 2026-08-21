-- FIX: trigger_moderate_message fails with constraint violation when app.edge_function_url is not set.

CREATE OR REPLACE FUNCTION public.trigger_moderate_message()
RETURNS TRIGGER AS $$
DECLARE
  edge_url text;
BEGIN
  -- Only fire for text content; media-only messages don't need text moderation
  IF NEW.content IS NULL OR trim(NEW.content) = '' OR NEW.type != 'text' THEN
    RETURN NEW;
  END IF;

  edge_url := current_setting('app.edge_function_url', true);

  -- Only perform the HTTP post if the edge function URL is configured
  IF edge_url IS NOT NULL AND edge_url != '' THEN
    PERFORM net.http_post(
      url     := edge_url || '/moderate-message',
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.anon_key', true)
      ),
      body    := jsonb_build_object(
        'messageId', NEW.id,
        'createdAt', NEW.created_at,
        'content',   NEW.content,
        'authorId',  NEW.sender_id
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
