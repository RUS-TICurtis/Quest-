import re
import os

files = [
    'supabase/migrations/20260805070002_schema_02_content.sql',
    'supabase/migrations/20260805070007_phase_2_get_edge_feed_rpc.sql',
    'supabase/migrations/20260805070014_feed_rankings.sql'
]

output = ''

for file in files:
    try:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            if 'schema_02_content' in file:
                match = re.search(r'CREATE TABLE public\.community_posts \([\s\S]*?\);', content)
                if match:
                    output += match.group(0) + '\n\n'
                
                match2 = re.search(r'CREATE TABLE public\.creator_videos \([\s\S]*?\);', content)
                if match2:
                    output += match2.group(0) + '\n\n'
                
                match3 = re.search(r'CREATE TABLE public\.video_engagement_events \([\s\S]*?\);', content)
                if match3:
                    output += match3.group(0) + '\n\n'

            elif 'phase_2_get_edge_feed_rpc' in file:
                output += content + '\n\n'
            
            elif 'feed_rankings' in file:
                output += content + '\n\n'
    except Exception as e:
        print(f"Error reading {file}: {e}")

with open('feed_migration_dump.sql', 'w', encoding='utf-8') as f:
    f.write(output)

print("Extracted to feed_migration_dump.sql")
