import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class LinkPreviewBubble extends StatelessWidget {
  final String title;
  final String? url;
  final String? description;
  final bool isMe;

  const LinkPreviewBubble({
    super.key,
    required this.title,
    this.url,
    this.description,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isEventLink = url?.startsWith('quest://events/') ?? false;
    final eventId = isEventLink ? url!.replaceFirst('quest://events/', '') : null;

    return GestureDetector(
      onTap: () {
        if (isEventLink && eventId != null) {
          context.push('/events/$eventId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.black.withValues(alpha: 0.2)
              : AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.white24 : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.questBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event, color: AppColors.questBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (isEventLink) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Text(
                          'Tap to view event details',
                          style: TextStyle(
                            color: AppColors.questBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: AppColors.questBlue, size: 12),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
