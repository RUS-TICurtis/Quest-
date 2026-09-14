with open("lib/features/interaction/feed/presentation/feed_screen.dart", "r") as f:
    content = f.read()

new_content = content.replace(
    """                        onTap: () async {
                          // Backend logic to like video
                          try {
                            final supabase = Supabase.instance.client;
                            await supabase.from('video_likes').insert({
                                'video_id': video.id,
                            });
                          } catch (_) {}
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Liked video!')),
                          );
                        },""",
    """                        onTap: () async {
                          // Backend logic to like video
                          try {
                            final supabase = Supabase.instance.client;
                            await supabase.from('video_likes').insert({
                                'video_id': video.id,
                            });
                          } catch (_) {}
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Liked video!')),
                          );
                        },"""
).replace(
    """                        onTap: () async {
                          // Backend logic to share video
                          try {
                            final supabase = Supabase.instance.client;
                            await supabase.rpc('increment_share_count', params: {'vid': video.id});
                          } catch (_) {}
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Sharing...')));
                        },""",
    """                        onTap: () async {
                          // Backend logic to share video
                          try {
                            final supabase = Supabase.instance.client;
                            await supabase.rpc('increment_share_count', params: {'vid': video.id});
                          } catch (_) {}
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Sharing...')));
                        },"""
)

with open("lib/features/interaction/feed/presentation/feed_screen.dart", "w") as f:
    f.write(new_content)
