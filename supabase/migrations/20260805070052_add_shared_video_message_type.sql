-- Migration to add 'shared_video' message type to the public.message_types table
-- to prevent foreign key constraint violations when users share creator videos in chat.

INSERT INTO public.message_types (value)
VALUES ('shared_video')
ON CONFLICT (value) DO NOTHING;
