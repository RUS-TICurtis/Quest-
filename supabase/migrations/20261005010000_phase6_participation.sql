-- Event RSVPs Migration
CREATE TABLE IF NOT EXISTS public.event_rsvps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'going',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(event_id, user_id)
);
ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read RSVPs" ON public.event_rsvps;
CREATE POLICY "Public read RSVPs" ON public.event_rsvps FOR SELECT USING (true);
DROP POLICY IF EXISTS "Members manage own RSVP" ON public.event_rsvps;
CREATE POLICY "Members manage own RSVP" ON public.event_rsvps FOR ALL USING (auth.uid() = user_id);

-- Community Members Migration
CREATE TABLE IF NOT EXISTS public.community_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(community_id, user_id)
);
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read memberships" ON public.community_members;
CREATE POLICY "Public read memberships" ON public.community_members FOR SELECT USING (true);
DROP POLICY IF EXISTS "Members manage own membership" ON public.community_members;
CREATE POLICY "Members manage own membership" ON public.community_members FOR ALL USING (auth.uid() = user_id);

-- Notifications Migration
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users read own notifications" ON public.notifications;
CREATE POLICY "Users read own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);

-- Server-Side XP Engine Migration
CREATE OR REPLACE FUNCTION award_xp(p_user_id UUID, p_amount INT, p_reason TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_xp INT;
    v_current_level INT;
    v_needed_xp INT;
BEGIN
    SELECT "currentXp", "level" INTO v_current_xp, v_current_level
    FROM public.profiles
    WHERE id = p_user_id;

    IF v_current_xp IS NULL THEN
        RETURN;
    END IF;

    v_current_xp := v_current_xp + p_amount;

    -- Level calculation (assumes level up at 100 * (1.25^(level-1)))
    LOOP
      v_needed_xp := (100 * power(1.25, v_current_level - 1))::INT;
      EXIT WHEN v_current_xp < v_needed_xp;

      v_current_xp := v_current_xp - v_needed_xp;
      v_current_level := v_current_level + 1;
    END LOOP;

    v_needed_xp := (100 * power(1.25, v_current_level - 1))::INT;

    UPDATE public.profiles
    SET "currentXp" = v_current_xp, "level" = v_current_level, "xpToNextLevel" = v_needed_xp
    WHERE id = p_user_id;

    -- Note: insert p_reason into audit / history if table exists
END;
$$;
