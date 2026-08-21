import 'package:flutter/material.dart';
import 'package:quest/features/society/communities/data/community_post.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final Community community;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.community,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: community.accentColor.withValues(alpha: 0.2),
                backgroundImage: post.authorAvatar != null 
                    ? NetworkImage(post.authorAvatar!) 
                    : null,
                child: post.authorAvatar == null 
                    ? Icon(Icons.person, size: 14, color: community.accentColor) 
                    : null,
              ),
              SizedBox(width: 8),
              Text(
                post.authorName,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              if (post.createdAt != null)
                Text(
                  timeago.format(post.createdAt!),
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          
          // Content
          Text(
            post.content,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          
          SizedBox(height: 12),
          
          // Actions
          Row(
            children: [
              _buildAction(
                icon: Icons.arrow_upward_rounded,
                label: post.upvotes.toString(),
                color: community.accentColor,
              ),
              SizedBox(width: 16),
              _buildAction(
                icon: Icons.chat_bubble_outline_rounded,
                label: post.commentCount.toString(),
                color: context.colors.textMuted,
              ),
              Spacer(),
              Icon(Icons.share_outlined, size: 16, color: context.colors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
