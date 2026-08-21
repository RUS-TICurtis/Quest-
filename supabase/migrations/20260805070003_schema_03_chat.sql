-- ============================================================================
-- SCHEMA GROUP 3: Chat & Messaging
-- Chats, participants, messages (partitioned), RPCs, moderation
-- ============================================================================

-- ── Chats ─────────────────────────────────────────────────────────────────────

CREATE TABLE public.chats (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  is_group                BOOLEAN DEFAULT false,
  group_name              TEXT,
  last_message            TEXT,
  last_message_at         TIMESTAMPTZ,
  last_message_sender_id  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_chats_last_message_at ON public.chats(last_message_at DESC);
CREATE INDEX idx_chats_created_at      ON public.chats(created_at DESC);

CREATE TRIGGER handle_chats_updated_at
  BEFORE UPDATE ON public.chats FOR EACH ROW EXECUTE PROCEDURE extensions.moddatetime(updated_at);

-- ── Chat Participants ─────────────────────────────────────────────────────────

CREATE TABLE public.chat_participants (
  chat_id      UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  unread_count INT DEFAULT 0,
  last_read_at TIMESTAMPTZ,
  joined_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (chat_id, user_id)
);

CREATE INDEX idx_cp_user    ON public.chat_participants(user_id);
CREATE INDEX idx_cp_chat_id ON public.chat_participants(chat_id);

-- ── Messages (Partitioned by Month) ──────────────────────────────────────────

CREATE TABLE public.messages (
  id                UUID DEFAULT gen_random_uuid(),
  chat_id           UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  type              TEXT DEFAULT 'text' REFERENCES public.message_types(value),
  content           TEXT,
  media_url         TEXT,
  metadata          JSONB DEFAULT '{}'::jsonb,
  client_id         UUID,                       -- deduplication key
  moderation_status TEXT DEFAULT 'pending'
    CHECK (moderation_status IN ('pending', 'approved', 'flagged')),
  deleted_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- Default catch-all + historical + 2026 partitions
CREATE TABLE public.msg_default PARTITION OF public.messages DEFAULT;
CREATE TABLE public.msg_2025_02 PARTITION OF public.messages FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
CREATE TABLE public.msg_2025_03 PARTITION OF public.messages FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');
CREATE TABLE public.msg_2025_04 PARTITION OF public.messages FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
CREATE TABLE public.msg_2025_05 PARTITION OF public.messages FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');
CREATE TABLE public.msg_2025_06 PARTITION OF public.messages FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');
CREATE TABLE public.msg_2025_07 PARTITION OF public.messages FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');
CREATE TABLE public.msg_2025_08 PARTITION OF public.messages FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
CREATE TABLE public.msg_2025_09 PARTITION OF public.messages FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE public.msg_2025_10 PARTITION OF public.messages FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE public.msg_2025_11 PARTITION OF public.messages FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE public.msg_2025_12 PARTITION OF public.messages FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE public.msg_2026_01 PARTITION OF public.messages FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE public.msg_2026_02 PARTITION OF public.messages FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE public.msg_2026_03 PARTITION OF public.messages FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE public.msg_2026_04 PARTITION OF public.messages FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE public.msg_2026_05 PARTITION OF public.messages FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE public.msg_2026_06 PARTITION OF public.messages FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE public.msg_2026_07 PARTITION OF public.messages FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE public.msg_2026_08 PARTITION OF public.messages FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE public.msg_2026_09 PARTITION OF public.messages FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE public.msg_2026_10 PARTITION OF public.messages FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE public.msg_2026_11 PARTITION OF public.messages FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE public.msg_2026_12 PARTITION OF public.messages FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

CREATE INDEX idx_msg_chat_created ON public.messages(chat_id, created_at DESC);
CREATE INDEX idx_msg_sender       ON public.messages(sender_id);
CREATE INDEX idx_msg_client_id    ON public.messages(client_id);

-- ── Chat Helper: participation check ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.is_chat_participant(p_chat_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.chat_participants WHERE chat_id = p_chat_id AND user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- ── Chat RLS ──────────────────────────────────────────────────────────────────

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Participants view chats" ON public.chats FOR SELECT
  USING (public.is_chat_participant(id));

ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Participants view members"      ON public.chat_participants FOR SELECT
  USING (public.is_chat_participant(chat_id));
CREATE POLICY "Users manage own participation" ON public.chat_participants FOR ALL
  USING (auth.uid() = user_id);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
-- FIX: receivers only see 'approved' messages; senders see their own regardless
CREATE POLICY "Participants read messages" ON public.messages FOR SELECT
  USING (
    public.is_chat_participant(chat_id)
    AND deleted_at IS NULL
    AND (moderation_status = 'approved' OR sender_id = auth.uid())
  );
CREATE POLICY "Participants send messages" ON public.messages FOR INSERT
  WITH CHECK (public.is_chat_participant(chat_id) AND auth.uid() = sender_id);
-- FIX: removed the open service-role UPDATE USING(true) policy — service role bypasses RLS by definition

-- ── Chat Triggers ─────────────────────────────────────────────────────────────

-- Block-check: prevents messaging blocked users in 1:1 chats
CREATE OR REPLACE FUNCTION public.check_message_block()
RETURNS TRIGGER AS $$
DECLARE
  v_is_group   BOOLEAN;
  v_receiver_id UUID;
BEGIN
  SELECT is_group INTO v_is_group FROM public.chats WHERE id = NEW.chat_id;
  IF NOT v_is_group THEN
    SELECT user_id INTO v_receiver_id
    FROM public.chat_participants
    WHERE chat_id = NEW.chat_id AND user_id != NEW.sender_id
    LIMIT 1;
    IF EXISTS (SELECT 1 FROM public.user_blocks WHERE blocker_id = v_receiver_id AND blocked_id = NEW.sender_id) THEN
      RAISE EXCEPTION 'Cannot send message. You have been blocked by this user.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_check_message_block ON public.messages;
CREATE TRIGGER trigger_check_message_block
  BEFORE INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.check_message_block();

-- Last-message updater trigger
CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chats SET
    last_message = CASE
      WHEN NEW.type = 'text'         THEN NEW.content
      WHEN NEW.type = 'image'        THEN '📷 Image'
      WHEN NEW.type = 'video'        THEN '🎥 Video'
      WHEN NEW.type = 'gif'          THEN 'GIF'
      WHEN NEW.type = 'sticker'      THEN 'Sticker'
      WHEN NEW.type = 'meme'         THEN 'Meme'
      WHEN NEW.type = 'recommendation' THEN '🎬 Recommended: ' || COALESCE((NEW.metadata->>'movieTitle'), 'Movie')
      WHEN NEW.type = 'video_share'  THEN '🎥 Shared Video'
      WHEN NEW.type = 'shared_post'  THEN '📝 Shared Post'
      ELSE 'New Message'
    END,
    last_message_at        = NEW.created_at,
    last_message_sender_id = NEW.sender_id,
    updated_at             = NOW()
  WHERE id = NEW.chat_id;

  UPDATE public.chat_participants
  SET unread_count = unread_count + 1
  WHERE chat_id = NEW.chat_id AND user_id != NEW.sender_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_chat_last_message ON public.messages;
CREATE TRIGGER trigger_update_chat_last_message
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.update_chat_last_message();

-- Async moderation via Edge Function (pg_net)
CREATE OR REPLACE FUNCTION public.trigger_moderate_message()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url     := current_setting('app.edge_function_url', true) || '/moderate-message',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || current_setting('app.anon_key', true)
    ),
    body    := jsonb_build_object('messageId', NEW.id, 'content', NEW.content, 'authorId', NEW.sender_id)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FIX: URL and key moved to database config settings instead of being hardcoded
DROP TRIGGER IF EXISTS trigger_async_moderate_msg ON public.messages;
CREATE TRIGGER trigger_async_moderate_msg
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.trigger_moderate_message();

-- ── Chat RPCs ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.create_chat_with_participants(user_a UUID, user_b UUID)
RETURNS UUID AS $$
DECLARE
  v_chat_id UUID;
BEGIN
  SELECT cp1.chat_id INTO v_chat_id
  FROM public.chat_participants cp1
  JOIN public.chat_participants cp2 ON cp1.chat_id = cp2.chat_id
  JOIN public.chats c ON c.id = cp1.chat_id
  WHERE cp1.user_id = user_a AND cp2.user_id = user_b AND c.is_group = false;

  IF v_chat_id IS NOT NULL THEN RETURN v_chat_id; END IF;

  INSERT INTO public.chats (is_group, last_message_at)
  VALUES (false, now()) RETURNING id INTO v_chat_id;

  INSERT INTO public.chat_participants (chat_id, user_id, joined_at) VALUES
    (v_chat_id, user_a, now()),
    (v_chat_id, user_b, now());

  RETURN v_chat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.mark_chat_read(p_chat_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.chat_participants
  SET unread_count = 0, last_read_at = now()
  WHERE chat_id = p_chat_id AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
