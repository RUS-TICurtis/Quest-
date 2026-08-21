import re

files = [
    'supabase/migrations/20260805070004_schema_04_library_analytics.sql'
]

output = ''

for file in files:
    try:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            match = re.search(r'CREATE TABLE public\.feed_rankings \([\s\S]*?\);', content)
            if match:
                output += match.group(0) + '\n\n'
                
                # Check for indexes
                idx_match = re.finditer(r'CREATE INDEX idx_feed_rankings[\s\S]*?;', content)
                for im in idx_match:
                    output += im.group(0) + '\n\n'
                    
                # RLS
                rls = re.finditer(r'ALTER TABLE public\.feed_rankings[\s\S]*?;|CREATE POLICY[\s\S]*?ON public\.feed_rankings[\s\S]*?;', content)
                for p in rls:
                    output += p.group(0) + '\n'
                output += '\n\n'

    except Exception as e:
        print(f"Error reading {file}: {e}")

with open(r'C:\Users\Curtis\.gemini\antigravity-ide\brain\37703219-8979-4f8e-b9b6-ec2a7da83c30\scratch\quest_feed_rankings.sql', 'w', encoding='utf-8') as f:
    f.write(output)

print("Extracted to quest_feed_rankings.sql")
