import 'package:flutter_test/flutter_test.dart';
import 'package:timer_desktop/core/utils/duration_formatters.dart';

void main() {
  group('DurationFormatters', () {
    test('formatHMS formats correctly with hours and minutes', () {
      expect(DurationFormatters.formatHMS(0), '00:00:00');
      expect(DurationFormatters.formatHMS(65), '00:01:05');
      expect(DurationFormatters.formatHMS(3665), '01:01:05');
      expect(DurationFormatters.formatHMS(5263), '01:27:43');
    });

    test('formatHMS without padding hours when hours is 0', () {
      expect(DurationFormatters.formatHMS(65, alwaysPadHours: false), '01:05');
      expect(DurationFormatters.formatHMS(3665, alwaysPadHours: false), '01:01:05');
    });

    test('formatHoursMinutes formats human-readable strings', () {
      expect(DurationFormatters.formatHoursMinutes(0), '0m');
      expect(DurationFormatters.formatHoursMinutes(45 * 60), '45m');
      expect(DurationFormatters.formatHoursMinutes(2 * 3600), '2h');
      expect(DurationFormatters.formatHoursMinutes((2 * 3600) + (15 * 60)), '2h 15m');
    });

    test('handles negative values gracefully', () {
      expect(DurationFormatters.formatHMS(-50), '00:00:00');
      expect(DurationFormatters.formatHoursMinutes(-10), '0m');
    });
  });
}
