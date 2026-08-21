import re
import os

scratch_dir = r'C:\Users\Curtis\.gemini\antigravity-ide\brain\37703219-8979-4f8e-b9b6-ec2a7da83c30\scratch'
feed_path = os.path.join(scratch_dir, 'quest_feed.sql')
rankings_path = os.path.join(scratch_dir, 'quest_feed_rankings.sql')

with open(feed_path, 'r', encoding='utf-8') as f:
    feed_sql = f.read()

with open(rankings_path, 'r', encoding='utf-8') as f:
    rankings_sql = f.read()

# Extract feed rankings block
match = re.search(r'-- ── Feed Rankings[\s\S]*', rankings_sql)
feed_rankings_block = match.group(0) if match else ""

# Combine
final_sql = """-- ============================================================================
-- Quest Feed & Posts Integration Migration
-- ============================================================================

-- Add missing columns to profiles for feed integration
ALTER TABLE public.profiles 
  ADD COLUMN IF NOT EXISTS username text,
  ADD COLUMN IF NOT EXISTS avatar_url text,
  ADD COLUMN IF NOT EXISTS role text DEFAULT 'user',
  ADD COLUMN IF NOT EXISTS creator_status text DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS is_banned boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_shadowbanned boolean DEFAULT false;

-- Create function needed for some RLS policies
CREATE OR REPLACE FUNCTION public.is_admin_or_reviewer()
RETURNS boolean AS \$\$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role IN ('admin', 'reviewer')
  );
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

"""

final_sql += feed_sql + '\n\n' + feed_rankings_block

# Replace foreign key constraints with simpler CHECK constraints for standalone migration
final_sql = re.sub(r'REFERENCES public\.feed_categories\(value\)', r"CHECK (category IN ('for_you', 'following', 'trending'))", final_sql)
final_sql = re.sub(r'REFERENCES public\.reaction_types\(value\)', r"CHECK (reaction_type IN ('heart', 'laugh', 'sad', 'angry', 'wow'))", final_sql)
final_sql = re.sub(r'REFERENCES public\.media_types\(value\)', r"CHECK (media_type IN ('movie', 'tv'))", final_sql)
final_sql = re.sub(r'REFERENCES public\.community_roles\(value\)', r"CHECK (role IN ('member', 'moderator', 'admin'))", final_sql)

# The communities table already exists in Quest, but we need to ensure the columns are present
# The community_posts table references public.communities(id)
# Quest has communities table in phase4_schema
final_sql = final_sql.replace('BIGINT REFERENCES public.communities(id)', 'UUID REFERENCES public.communities(id)')
final_sql = final_sql.replace('community_id     BIGINT', 'community_id     UUID')

with open(r'supabase\migrations\20260821000000_quest_feed_integration.sql', 'w', encoding='utf-8') as f:
    f.write(final_sql)

print("Created 20260821000000_quest_feed_integration.sql")
