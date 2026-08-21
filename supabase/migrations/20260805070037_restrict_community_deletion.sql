-- Restrict community deletion strictly to admins and reviewers (is_admin_or_reviewer)
-- Drop existing delete policies on communities if any exist (to avoid duplicates or overrides)
DROP POLICY IF EXISTS "Admins delete communities" ON public.communities;
DROP POLICY IF EXISTS "Users delete own communities" ON public.communities;

-- Create the strict policy for deletion
CREATE POLICY "Admins delete communities" ON public.communities
  FOR DELETE USING (public.is_admin_or_reviewer());
