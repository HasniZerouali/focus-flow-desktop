import 'package:flutter_test/flutter_test.dart';
import 'package:timer_desktop/core/utils/productivity_score.dart';

void main() {
  group('ProductivityScoreCalculator', () {
    test('returns 0 when there is no activity', () {
      final score = ProductivityScoreCalculator.calculate(
        focusMinutes: 0,
        targetFocusMinutes: 120,
        completedSessions: 0,
        completedTasks: 0,
        targetTasks: 3,
        distractionCount: 0,
      );

      expect(score, 0);
      expect(ProductivityScoreCalculator.getLabel(score), contains('Ready to Focus'));
    });

    test('calculates score proportionally when target is reached', () {
      final score = ProductivityScoreCalculator.calculate(
        focusMinutes: 120,
        targetFocusMinutes: 120,
        completedSessions: 4,
        completedTasks: 3,
        targetTasks: 3,
        distractionCount: 0,
      );

      // Focus: 32, Sessions: 25, Tasks: 20, Boost: 10 = 87
      expect(score, greaterThanOrEqualTo(80));
      expect(score, lessThanOrEqualTo(100));
      expect(ProductivityScoreCalculator.getLabel(score), contains('Highly Productive'));
    });

    test('deducts points for distractions but clamps to 0', () {
      final scoreWithDistractions = ProductivityScoreCalculator.calculate(
        focusMinutes: 60,
        targetFocusMinutes: 120,
        completedSessions: 1,
        completedTasks: 1,
        targetTasks: 3,
        distractionCount: 10, // penalty up to 15
      );

      final scoreWithoutDistractions = ProductivityScoreCalculator.calculate(
        focusMinutes: 60,
        targetFocusMinutes: 120,
        completedSessions: 1,
        completedTasks: 1,
        targetTasks: 3,
        distractionCount: 0,
      );

      expect(scoreWithDistractions, lessThan(scoreWithoutDistractions));
      expect(scoreWithDistractions, greaterThanOrEqualTo(0));
    });

    test('clamps score maximum to 100', () {
      final score = ProductivityScoreCalculator.calculate(
        focusMinutes: 500,
        targetFocusMinutes: 120,
        completedSessions: 10,
        completedTasks: 10,
        targetTasks: 3,
        distractionCount: 0,
      );

      expect(score, lessThanOrEqualTo(100));
    });
  });
}
