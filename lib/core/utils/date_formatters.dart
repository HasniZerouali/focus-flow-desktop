import 'package:intl/intl.dart';

class DateFormatters {
  DateFormatters._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _fullDate = DateFormat('EEEE, MMMM d, y');
  static final DateFormat _isoDay = DateFormat('yyyy-MM-dd');

  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatShortDate(DateTime dt) => _shortDate.format(dt);
  static String formatFullDate(DateTime dt) => _fullDate.format(dt);
  static String toIsoDay(DateTime dt) => _isoDay.format(dt);

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return isSameDay(now, dt);
  }

  static bool isYesterday(DateTime dt) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday, dt);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String groupDayTitle(DateTime dt) {
    if (isToday(dt)) return 'Today';
    if (isYesterday(dt)) return 'Yesterday';
    return DateFormat('EEEE, MMMM d').format(dt);
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
