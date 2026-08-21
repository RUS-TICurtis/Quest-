import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class CreateScreen extends ConsumerWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Create'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 64,
              color: context.colors.questBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Create Experience',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: context.colors.textPrimary),
            ),
            SizedBox(height: 32),
            _buildCreateOption(
              context, 
              icon: Icons.videocam_outlined, 
              title: 'Upload Vlog / Activity', 
              subtitle: 'Powered by Mux',
              onTap: () {
                // TODO: Integrate with create-mux-upload edge function
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mux Video Upload coming soon')),
                );
              },
            ),
            SizedBox(height: 16),
            _buildCreateOption(
              context, 
              icon: Icons.image_outlined, 
              title: 'Share Image', 
              subtitle: 'Powered by Supabase Storage',
              onTap: () {
                // TODO: Integrate with Supabase Storage
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Image Upload coming soon')),
                );
              },
            ),
            SizedBox(height: 16),
            _buildCreateOption(
              context, 
              icon: Icons.search_outlined, 
              title: 'Search "How To"s', 
              subtitle: 'Powered by YouTube API',
              onTap: () {
                // TODO: Hook into fetch-youtube-trailers equivalent
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('YouTube Search coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: context.colors.questBlue, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
