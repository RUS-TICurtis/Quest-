import 'package:intl/intl.dart';

class TimeUtils {
  static String formatStoryTime(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } else {
      // Check if it was yesterday
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final dateAtMidnight = DateTime(date.year, date.month, date.day);
      
      if (dateAtMidnight == yesterday) {
        final timeFormat = DateFormat('h:mm a');
        return 'Yesterday at ${timeFormat.format(date)}';
      } else {
        // Older than yesterday
        final dateFormat = DateFormat('MMMM d${_getDaySuffix(date.day)}');
        return dateFormat.format(date);
      }
    }
  }

  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
