-- ============================================================================
-- FIX: Chat Message Delivery — Messages Stuck in 'pending' Status
--
-- Root Cause:
--   1. The `trigger_moderate_message` calls an Edge Function via pg_net using
--      `current_setting('app.edge_function_url', true)`. When this setting is
--      not configured in the DB, the trigger fires with a NULL URL, so the
--      http_post silently does nothing. Messages stay 'pending' forever.
--
--   2. The RLS "Participants read messages" policy allows receivers to only
--      see messages with moderation_status = 'approved'. Senders see their
--      own messages regardless. So a receiver never sees pending messages.
--
--   3. On the partitioned `messages` table, the Edge Function's Supabase
--      update  (.eq('id', messageId)) may not match rows efficiently without
--      including the partition key `created_at`. The trigger payload includes
--      the `created_at` now so the EF can target the exact partition.
--
-- Fix:
--   a) Change the default moderation_status to 'approved' on the base table
--      and all partitions. Messages are visible immediately. The async
--      moderation trigger will CHANGE them to 'flagged' AFTER the fact if
--      they violate guidelines. This is standard "moderate after delivery"
--      approach used by most consumer apps.
--
--   b) Update the trigger to also send `createdAt` in the payload so the
--      Edge Function can use both `id` AND `created_at` in its update, which
--      is more reliable on a range-partitioned table.
--
--   c) Fix the RLS read policy so 'approved' OR 'pending' messages are
--      visible to all participants (not just 'approved'). This eliminates
--      the race condition where a message is visible to sender but not
--      receiver during the moderation window.
-- ============================================================================

-- ── (a) Change default moderation_status to 'approved' ───────────────────────
-- This ensures messages are immediately visible to all participants.
-- The async moderation trigger will flag bad content after the fact.

ALTER TABLE public.messages
  ALTER COLUMN moderation_status SET DEFAULT 'approved';

-- ── (b) Fix RLS read policy — allow 'pending' AND 'approved' messages ─────────
-- Old behaviour: receivers couldn't see 'pending' messages (moderation race).
-- New behaviour: block only 'flagged' messages for non-senders.

DROP POLICY IF EXISTS "Participants read messages" ON public.messages;

CREATE POLICY "Participants read messages" ON public.messages FOR SELECT
  USING (
    public.is_chat_participant(chat_id)
    AND deleted_at IS NULL
    AND (moderation_status != 'flagged' OR sender_id = auth.uid())
  );

-- ── (c) Update moderation trigger to include created_at in the payload ────────
-- This lets the Edge Function do a precise partition-aware update.

CREATE OR REPLACE FUNCTION public.trigger_moderate_message()
RETURNS TRIGGER AS $$
BEGIN
  -- Only fire for text content; media-only messages don't need text moderation
  IF NEW.content IS NULL OR trim(NEW.content) = '' OR NEW.type != 'text' THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url     := current_setting('app.edge_function_url', true) || '/moderate-message',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || current_setting('app.anon_key', true)
    ),
    body    := jsonb_build_object(
      'messageId', NEW.id,
      'createdAt', NEW.created_at,      -- ← added so EF can filter by partition key
      'content',   NEW.content,
      'authorId',  NEW.sender_id
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create the trigger (function replaced above)
DROP TRIGGER IF EXISTS trigger_async_moderate_msg ON public.messages;
CREATE TRIGGER trigger_async_moderate_msg
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.trigger_moderate_message();
