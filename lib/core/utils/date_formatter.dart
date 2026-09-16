import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatTimelineDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = today.difference(target).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7 && difference > 0) {
      return DateFormat('EEEE').format(dateTime); // e.g. "Monday"
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM d').format(dateTime); // e.g. "Sep 15"
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime); // e.g. "Sep 15, 2025"
    }
  }

  static String formatFullDate(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  static String formatDuration(int durationMinutes) {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
