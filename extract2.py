import re

files = [
    'supabase/migrations/20260805070002_schema_02_content.sql',
    'supabase/migrations/20260805070005_schema_05_feed_ml.sql',
    'supabase/migrations/20260805070113_get_edge_feed_v4_fix_cursor.sql'
]

output = "-- Consolidated Quest Feed & Posts Migration\n\n"

def extract_block(content, start_pattern, end_pattern=r'(?:\n\n-- ──|\Z)'):
    matches = re.finditer(start_pattern, content)
    for match in matches:
        start_idx = match.start()
        end_match = re.search(end_pattern, content[start_idx+1:])
        if end_match:
            end_idx = start_idx + 1 + end_match.start()
            return content[start_idx:end_idx].strip()
        else:
            return content[start_idx:].strip()
    return ""

for file in files:
    try:
        with open(file, 'r', encoding='utf-8') as f:
            content = f.read()
            if 'schema_02_content' in file:
                output += extract_block(content, r'-- ── Community Posts') + '\n\n'
                output += extract_block(content, r'-- ── Community Comments') + '\n\n'
                output += extract_block(content, r'-- ── Creator Videos') + '\n\n'
                output += extract_block(content, r'-- ── Video Engagement Events') + '\n\n'
                output += extract_block(content, r'-- ── Video Reactions') + '\n\n'
                output += extract_block(content, r'-- ── Video Comments') + '\n\n'
            elif 'schema_05_feed_ml' in file:
                output += extract_block(content, r'-- ── Feed Rankings') + '\n\n'
                output += extract_block(content, r'-- ── Feed Impressions') + '\n\n'
            elif 'get_edge_feed' in file:
                output += content + '\n\n'
    except Exception as e:
        print(f"Error reading {file}: {e}")

with open(r'C:\Users\Curtis\.gemini\antigravity-ide\brain\37703219-8979-4f8e-b9b6-ec2a7da83c30\scratch\quest_feed.sql', 'w', encoding='utf-8') as f:
    f.write(output)

print("Extracted to quest_feed.sql")
