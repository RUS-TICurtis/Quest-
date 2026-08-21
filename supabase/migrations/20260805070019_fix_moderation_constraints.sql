ALTER TABLE public.moderation_actions DROP CONSTRAINT IF EXISTS moderation_actions_target_type_check;
ALTER TABLE public.moderation_actions ADD CONSTRAINT moderation_actions_target_type_check CHECK (target_type IN (
  'video', 'comment', 'user', 'community_post', 'community', 'chat_message', 'system'
));

ALTER TABLE public.moderation_actions DROP CONSTRAINT IF EXISTS moderation_actions_action_check;
ALTER TABLE public.moderation_actions ADD CONSTRAINT moderation_actions_action_check CHECK (action IN (
  'approve', 'reject', 'remove', 'suppress', 'unsuppress',
  'ban', 'unban', 'suspend', 'unsuspend', 'warn', 'escalate', 'broadcast'
));
