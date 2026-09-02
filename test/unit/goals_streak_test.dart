import 'package:flutter_test/flutter_test.dart';
import 'package:timer_desktop/core/storage/models.dart';
import 'package:timer_desktop/core/utils/date_formatters.dart';

void main() {
  group('Streak Calculation Logic', () {
    test('counts consecutive days meeting minimum minutes threshold', () {
      final now = DateTime.now();
      const thresholdMinutes = 20;

      // Create 3 consecutive days of sessions: today, yesterday, day before yesterday
      final sessions = [
        // Today: 30 mins
        FocusSessionModel(
          id: 's1',
          title: 'Day 1 Work',
          categoryId: 'Development',
          categoryName: 'Development',
          startedAt: now.subtract(const Duration(minutes: 30)),
          endedAt: now,
          durationSeconds: 30 * 60,
          mode: TimerMode.free,
          state: SessionState.completed,
        ),
        // Yesterday: 25 mins
        FocusSessionModel(
          id: 's2',
          title: 'Day 2 Work',
          categoryId: 'Development',
          categoryName: 'Development',
          startedAt: now.subtract(const Duration(days: 1, minutes: 25)),
          endedAt: now.subtract(const Duration(days: 1)),
          durationSeconds: 25 * 60,
          mode: TimerMode.free,
          state: SessionState.completed,
        ),
        // 2 days ago: 40 mins
        FocusSessionModel(
          id: 's3',
          title: 'Day 3 Work',
          categoryId: 'Development',
          categoryName: 'Development',
          startedAt: now.subtract(const Duration(days: 2, minutes: 40)),
          endedAt: now.subtract(const Duration(days: 2)),
          durationSeconds: 40 * 60,
          mode: TimerMode.free,
          state: SessionState.completed,
        ),
      ];

      // Calculate streak
      final dayMinutes = <String, int>{};
      for (final s in sessions) {
        if (!s.state.isCompleted) continue;
        final dayKey = DateFormatters.toIsoDay(s.startedAt);
        dayMinutes[dayKey] = (dayMinutes[dayKey] ?? 0) + (s.durationSeconds / 60).round();
      }

      final todayKey = DateFormatters.toIsoDay(now);
      final todayMins = dayMinutes[todayKey] ?? 0;
      final metThresholdToday = todayMins >= thresholdMinutes;

      int streak = 0;
      DateTime checkDate = metThresholdToday ? now : now.subtract(const Duration(days: 1));

      while (true) {
        final key = DateFormatters.toIsoDay(checkDate);
        final mins = dayMinutes[key] ?? 0;
        if (mins >= thresholdMinutes) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      expect(streak, 3);
      expect(metThresholdToday, true);
    });

    test('preserves existing streak earlier in the day before meeting today threshold', () {
      final now = DateTime.now();
      const thresholdMinutes = 20;

      // Only yesterday met threshold, today has 5 mins so far
      final sessions = [
        FocusSessionModel(
          id: 's1',
          title: 'Short today',
          categoryId: 'Development',
          categoryName: 'Development',
          startedAt: now.subtract(const Duration(minutes: 5)),
          endedAt: now,
          durationSeconds: 5 * 60,
          mode: TimerMode.free,
          state: SessionState.completed,
        ),
        FocusSessionModel(
          id: 's2',
          title: 'Solid yesterday',
          categoryId: 'Development',
          categoryName: 'Development',
          startedAt: now.subtract(const Duration(days: 1, minutes: 45)),
          endedAt: now.subtract(const Duration(days: 1)),
          durationSeconds: 45 * 60,
          mode: TimerMode.free,
          state: SessionState.completed,
        ),
      ];

      final dayMinutes = <String, int>{};
      for (final s in sessions) {
        if (!s.state.isCompleted) continue;
        final dayKey = DateFormatters.toIsoDay(s.startedAt);
        dayMinutes[dayKey] = (dayMinutes[dayKey] ?? 0) + (s.durationSeconds / 60).round();
      }

      final todayKey = DateFormatters.toIsoDay(now);
      final todayMins = dayMinutes[todayKey] ?? 0;
      final metThresholdToday = todayMins >= thresholdMinutes;

      int streak = 0;
      DateTime checkDate = metThresholdToday ? now : now.subtract(const Duration(days: 1));

      while (true) {
        final key = DateFormatters.toIsoDay(checkDate);
        final mins = dayMinutes[key] ?? 0;
        if (mins >= thresholdMinutes) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      // Yesterday is preserved as a 1-day streak, pending today's completion
      expect(streak, 1);
      expect(metThresholdToday, false);
    });
  });
}
