import 'dart:math';

class ProductivityScoreCalculator {
  ProductivityScoreCalculator._();

  /// Calculates a motivational Productivity Score (0–100).
  /// Note: Explicitly labeled as motivational only — not scientific.
  static int calculate({
    required int focusMinutes,
    required int targetFocusMinutes,
    required int completedSessions,
    required int completedTasks,
    required int targetTasks,
    required int distractionCount,
  }) {
    if (focusMinutes <= 0 && completedSessions <= 0 && completedTasks <= 0) {
      return 0;
    }

    final safeTargetFocus = max(targetFocusMinutes, 30);
    final safeTargetTasks = max(targetTasks, 1);

    // 1. Focus time ratio (max 40 points)
    final focusRatio = (focusMinutes / safeTargetFocus).clamp(0.0, 1.25);
    final focusPoints = (focusRatio * 32.0).clamp(0.0, 40.0);

    // 2. Session consistency (max 25 points)
    final sessionPoints = min(completedSessions * 8.0, 25.0);

    // 3. Task achievement (max 25 points)
    final taskRatio = (completedTasks / safeTargetTasks).clamp(0.0, 1.25);
    final taskPoints = (taskRatio * 20.0).clamp(0.0, 25.0);

    // 4. Distraction penalty (deduct up to 15 points)
    final distractionPenalty = (distractionCount * 3.0).clamp(0.0, 15.0);

    // Base motivational boost (+10 if at least 1 session completed)
    final baselineBoost = completedSessions > 0 ? 10.0 : 0.0;

    final rawScore = (focusPoints + sessionPoints + taskPoints + baselineBoost - distractionPenalty).round();
    return rawScore.clamp(0, 100);
  }

  static String getLabel(int score) {
    if (score >= 90) return 'Peak Focus ⚡';
    if (score >= 75) return 'Highly Productive 🚀';
    if (score >= 50) return 'Solid Progress 🎯';
    if (score >= 25) return 'Getting Started 🌱';
    return 'Ready to Focus 💡';
  }
}
