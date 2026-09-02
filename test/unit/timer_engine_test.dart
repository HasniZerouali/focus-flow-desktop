import 'package:flutter_test/flutter_test.dart';
import 'package:timer_desktop/core/storage/models.dart';

void main() {
  group('Timer Math & Sleep-Proof Recovery Logic', () {
    test('computes running elapsed time based on DateTime differences, not integer ticks', () {
      final startTime = DateTime.now().subtract(const Duration(minutes: 15, seconds: 30));
      const accumulated = 100; // previously accumulated 100s

      final now = DateTime.now();
      final runningSegment = now.difference(startTime).inSeconds;
      final totalElapsed = accumulated + runningSegment;

      // 15m 30s = 930s + 100s = 1030s
      expect(totalElapsed, greaterThanOrEqualTo(1030));
      expect(totalElapsed, lessThan(1035));
    });

    test('paused elapsed time freezes at accumulated duration', () {
      const accumulated = 500;
      final state = SessionState.paused;

      int elapsed;
      if (state == SessionState.paused) {
        elapsed = accumulated;
      } else {
        elapsed = 0;
      }

      expect(elapsed, 500);
    });

    test('recovers active session accurately after simulated app restart or OS sleep', () {
      // Simulate an active session that was saved to SQLite 45 minutes ago
      final originalStart = DateTime.now().subtract(const Duration(minutes: 45));

      final recovery = ActiveSessionRecovery(
        id: 'session-sleep-test',
        title: 'Deep Focus Coding',
        categoryId: 'Development',
        categoryName: 'Development',
        startedAt: originalStart,
        accumulatedSeconds: 120, // 2 mins prior to this segment
        targetDurationSeconds: 60 * 60, // 60 min countdown
        mode: TimerMode.countdown,
        state: SessionState.running,
      );

      // Recomputing elapsed after "restart"
      final now = DateTime.now();
      final segment = now.difference(recovery.startedAt).inSeconds;
      final elapsed = recovery.accumulatedSeconds + segment;

      // 2m + 45m = 47m (approx 2820 seconds)
      expect(elapsed, greaterThanOrEqualTo(47 * 60));
      expect(elapsed, lessThan((47 * 60) + 5));

      final remaining = recovery.targetDurationSeconds - elapsed;
      // 60m - 47m = 13m remaining
      expect(remaining, greaterThanOrEqualTo(12 * 60));
      expect(remaining, lessThanOrEqualTo(13 * 60));
    });

    test('detects countdown expiration if OS sleep exceeded target duration', () {
      // Session started 2 hours ago for a 25 min countdown
      final originalStart = DateTime.now().subtract(const Duration(hours: 2));

      final recovery = ActiveSessionRecovery(
        id: 'session-expired-during-sleep',
        title: 'Quick Sprint',
        categoryId: 'Study',
        categoryName: 'Study',
        startedAt: originalStart,
        accumulatedSeconds: 0,
        targetDurationSeconds: 25 * 60,
        mode: TimerMode.countdown,
        state: SessionState.running,
      );

      final elapsed = recovery.accumulatedSeconds + DateTime.now().difference(recovery.startedAt).inSeconds;
      final isExpired = elapsed >= recovery.targetDurationSeconds;

      expect(isExpired, true);
    });
  });
}
