import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
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
    final eventId = isEventLink
        ? url!.replaceFirst('quest://events/', '')
        : null;

    return GestureDetector(
      onTap: () {
        if (isEventLink && eventId != null) {
          context.push('/events/$eventId');
        }
      },
      child: Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.black.withValues(alpha: 0.2)
              : context.colors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isMe ? Colors.white24 : context.colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.questBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event,
                color: context.colors.questBlue,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (description != null) ...[
                    SizedBox(height: 4),
                    Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                  if (isEventLink) ...[
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Tap to view event details',
                          style: TextStyle(
                            color: context.colors.questBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: context.colors.questBlue,
                          size: 12,
                        ),
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
