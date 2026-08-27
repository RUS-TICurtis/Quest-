-- Profile Enhancements
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS "username" text UNIQUE,
ADD COLUMN IF NOT EXISTS "avatarUrl" text,
ADD COLUMN IF NOT EXISTS "bio" text;

-- Chat Rooms
CREATE TABLE public.chat_rooms (
  "id" uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  "createdAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "lastMessageText" text,
  "lastMessageTime" timestamp with time zone,
  "isGroup" boolean DEFAULT false,
  "name" text,
  "avatarUrl" text
);

-- Chat Participants (Links users to rooms)
CREATE TABLE public.chat_participants (
  "roomId" uuid REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  "userId" uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  "joinedAt" timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  "lastReadAt" timestamp with time zone,
  PRIMARY KEY ("roomId", "userId")
);

-- Update Chat Messages
ALTER TABLE public.chat_messages
ADD COLUMN IF NOT EXISTS "roomId" uuid REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS "senderId" uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS "status" text DEFAULT 'sent';

-- RLS for Chat Rooms
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their chat rooms" ON public.chat_rooms
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants
      WHERE "roomId" = chat_rooms.id AND "userId" = auth.uid()
    )
  );
CREATE POLICY "Users can insert chat rooms" ON public.chat_rooms
  FOR INSERT WITH CHECK (true); -- Or check if they are a participant
CREATE POLICY "Users can update their chat rooms" ON public.chat_rooms
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants
      WHERE "roomId" = chat_rooms.id AND "userId" = auth.uid()
    )
  );

-- RLS for Chat Participants
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view participants in their rooms" ON public.chat_participants
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_participants cp
      WHERE cp."roomId" = chat_participants."roomId" AND cp."userId" = auth.uid()
    )
  );
CREATE POLICY "Users can insert participants" ON public.chat_participants
  FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update their participant record" ON public.chat_participants
  FOR UPDATE USING ("userId" = auth.uid());

