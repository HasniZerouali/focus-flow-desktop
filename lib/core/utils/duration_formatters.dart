class DurationFormatters {
  DurationFormatters._();

  /// Formats seconds into HH:MM:SS or MM:SS (if padHours is true, always HH:MM:SS)
  static String formatHMS(int totalSeconds, {bool alwaysPadHours = true}) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (alwaysPadHours || hours > 0) {
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Formats seconds into "2h 45m" or "45m" or "0m"
  static String formatHoursMinutes(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Formats seconds into "X min" or "X hr Y min"
  static String formatDetailed(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds sec';
    return formatHoursMinutes(totalSeconds);
  }
}
