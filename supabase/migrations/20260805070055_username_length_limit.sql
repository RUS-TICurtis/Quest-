-- Migration to limit username length to 20 characters going forward.

-- 1. Update the handle_new_user function to truncate generated usernames to 20 characters instead of 30.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  _username     TEXT;
  _display_name TEXT;
  _first_name   TEXT;
  _last_name    TEXT;
BEGIN
  _username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );
  -- Truncate sanitised username to 20 characters
  _username  := left(regexp_replace(trim(_username), '[^a-zA-Z0-9_\.]', '', 'g'), 20);
  IF length(_username) < 1 THEN _username := 'user_' || substring(NEW.id::text, 1, 8); END IF;

  _first_name := COALESCE(
    NEW.raw_user_meta_data->>'first_name',
    NULLIF(split_part(COALESCE(NEW.raw_user_meta_data->>'full_name', ''), ' ', 1), '')
  );
  _last_name := COALESCE(
    NEW.raw_user_meta_data->>'last_name',
    NULLIF(split_part(COALESCE(NEW.raw_user_meta_data->>'full_name', ''), ' ', 2), '')
  );

  -- Build display_name: prefer explicit full_name, else first+last, else username
  _display_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''),
    NULLIF(trim(COALESCE(_first_name, '') || ' ' || COALESCE(_last_name, '')), ''),
    _username
  );

  INSERT INTO public.profiles (id, username, display_name, first_name, last_name)
  VALUES (NEW.id, _username, _display_name, _first_name, _last_name)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create trigger to enforce 20-character maximum length on all profile updates/inserts
CREATE OR REPLACE FUNCTION public.enforce_username_length()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.username IS NOT NULL AND char_length(NEW.username) > 20 THEN
    RAISE EXCEPTION 'Username must be 20 characters or less';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_enforce_username_length ON public.profiles;

CREATE TRIGGER tr_enforce_username_length
  BEFORE INSERT OR UPDATE OF username ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.enforce_username_length();
