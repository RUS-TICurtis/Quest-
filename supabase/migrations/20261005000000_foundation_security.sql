-- ============================================================================
-- Foundation security & identity hardening (audit 2026-10-05)
--  * Replace "public update/insert profiles" dev policies with own-row policies
--  * Protect server-owned profile columns from client writes
--  * Case-insensitive unique usernames + format constraint + availability RPC
--  * Fix infinite RLS recursion on chat_participants / chat_rooms
--  * Block anonymous (guest) sessions from chat writes
-- ============================================================================

-- ── Helpers ─────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_guest()
RETURNS boolean LANGUAGE sql STABLE AS $$
  SELECT COALESCE((auth.jwt() ->> 'is_anonymous')::boolean, false);
$$;

-- ── Profiles RLS ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Allow public insert to profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow public update to profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users update own profile" ON public.profiles;

CREATE POLICY "Users insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id AND NOT public.is_guest());
CREATE POLICY "Users update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id AND NOT public.is_guest())
  WITH CHECK (auth.uid() = id AND NOT public.is_guest());

-- Server-owned columns can only change via service_role (edge functions / RPCs).
CREATE OR REPLACE FUNCTION public.protect_profile_columns()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF COALESCE(auth.role(), 'service_role') = 'service_role' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'INSERT' THEN
    NEW."level" := 1; NEW."currentXp" := 0; NEW."xpToNextLevel" := 100;
    NEW."streak" := 0; NEW."badges" := '{}'; NEW.role := 'user';
    NEW.creator_status := 'pending'; NEW.is_banned := false;
    NEW.is_shadowbanned := false;
  ELSE
    NEW."level" := OLD."level"; NEW."currentXp" := OLD."currentXp";
    NEW."xpToNextLevel" := OLD."xpToNextLevel"; NEW."streak" := OLD."streak";
    NEW."badges" := OLD."badges"; NEW.role := OLD.role;
    NEW.creator_status := OLD.creator_status; NEW.is_banned := OLD.is_banned;
    NEW.is_shadowbanned := OLD.is_shadowbanned;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_columns ON public.profiles;
CREATE TRIGGER trg_protect_profile_columns
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_profile_columns();

-- ── Usernames ───────────────────────────────────────────────────────────────
-- The legacy column constraint is case-sensitive; enforce case-insensitively.
CREATE UNIQUE INDEX IF NOT EXISTS profiles_username_lower_idx
  ON public.profiles (lower(username)) WHERE username IS NOT NULL;

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_username_format;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_username_format
  CHECK (username IS NULL OR username ~ '^[a-z0-9_]{3,30}$') NOT VALID;

CREATE OR REPLACE FUNCTION public.check_username_available(p_username text)
RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE lower(username) = lower(trim(p_username)) AND id <> auth.uid()
  );
$$;
REVOKE ALL ON FUNCTION public.check_username_available(text) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.check_username_available(text) TO authenticated;

-- ── Chat RLS: remove self-referencing policies (500 "infinite recursion") ───
CREATE OR REPLACE FUNCTION public.is_chat_participant(p_room uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.chat_participants
    WHERE "roomId" = p_room AND "userId" = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "Users can view their chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Users can update their chat rooms" ON public.chat_rooms;
DROP POLICY IF EXISTS "Users can insert chat rooms" ON public.chat_rooms;
CREATE POLICY "Users can view their chat rooms" ON public.chat_rooms
  FOR SELECT USING (public.is_chat_participant(id));
CREATE POLICY "Users can update their chat rooms" ON public.chat_rooms
  FOR UPDATE USING (public.is_chat_participant(id));
CREATE POLICY "Members create chat rooms" ON public.chat_rooms
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND NOT public.is_guest());

DROP POLICY IF EXISTS "Users can view participants in their rooms" ON public.chat_participants;
DROP POLICY IF EXISTS "Users can insert participants" ON public.chat_participants;
CREATE POLICY "Users can view participants in their rooms" ON public.chat_participants
  FOR SELECT USING (public.is_chat_participant("roomId"));
CREATE POLICY "Members add participants" ON public.chat_participants
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL AND NOT public.is_guest());
