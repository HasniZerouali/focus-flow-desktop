import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/models.dart';
import '../utils/date_formatters.dart';
import 'sessions_provider.dart';
import 'settings_provider.dart';
import 'tasks_provider.dart';

class DailyGoalProgress {
  final int todayFocusMinutes;
  final int targetFocusMinutes;
  final double focusProgress; // 0.0 to 1.0+
  final int todayTasksCompleted;
  final int targetTasksCompleted;
  final double tasksProgress; // 0.0 to 1.0+
  final bool isFocusGoalHit;
  final bool isTaskGoalHit;
  final bool isAllGoalsHit;

  const DailyGoalProgress({
    required this.todayFocusMinutes,
    required this.targetFocusMinutes,
    required this.focusProgress,
    required this.todayTasksCompleted,
    required this.targetTasksCompleted,
    required this.tasksProgress,
    required this.isFocusGoalHit,
    required this.isTaskGoalHit,
    required this.isAllGoalsHit,
  });
}

class StreakInfo {
  final int currentStreak;
  final bool metThresholdToday;
  final int minMinutesThreshold;
  final List<DateTime> streakDays;

  const StreakInfo({
    required this.currentStreak,
    required this.metThresholdToday,
    required this.minMinutesThreshold,
    required this.streakDays,
  });
}

final dailyGoalProgressProvider = Provider<DailyGoalProgress>((ref) {
  final sessionsAsync = ref.watch(sessionsProvider);
  final tasksAsync = ref.watch(tasksProvider);
  final settings = ref.watch(settingsProvider);

  final sessions = sessionsAsync.valueOrNull ?? [];
  final tasks = tasksAsync.valueOrNull ?? [];

  // Calculate today's focus minutes
  final todaySessions = sessions.where((s) => DateFormatters.isToday(s.startedAt) && s.state.isCompleted);
  final todayFocusSeconds = todaySessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
  final todayFocusMinutes = (todayFocusSeconds / 60).round();

  // Calculate today's completed tasks
  final todayTasks = tasks.where((t) => t.completed && t.completedAt != null && DateFormatters.isToday(t.completedAt!));
  final todayTasksCount = todayTasks.length;

  final targetFocus = settings.dailyFocusGoalMinutes > 0 ? settings.dailyFocusGoalMinutes : 120;
  final targetTasks = settings.dailyTaskGoal > 0 ? settings.dailyTaskGoal : 3;

  final focusProgress = (todayFocusMinutes / targetFocus).clamp(0.0, 2.0);
  final tasksProgress = (todayTasksCount / targetTasks).clamp(0.0, 2.0);

  final isFocusHit = todayFocusMinutes >= targetFocus;
  final isTaskHit = todayTasksCount >= targetTasks;

  return DailyGoalProgress(
    todayFocusMinutes: todayFocusMinutes,
    targetFocusMinutes: targetFocus,
    focusProgress: focusProgress,
    todayTasksCompleted: todayTasksCount,
    targetTasksCompleted: targetTasks,
    tasksProgress: tasksProgress,
    isFocusGoalHit: isFocusHit,
    isTaskGoalHit: isTaskHit,
    isAllGoalsHit: isFocusHit && isTaskHit,
  );
});

final streakProvider = Provider<StreakInfo>((ref) {
  final sessionsAsync = ref.watch(sessionsProvider);
  final settings = ref.watch(settingsProvider);

  final sessions = sessionsAsync.valueOrNull ?? [];
  final threshold = settings.streakMinMinutes;

  // Group focus minutes by ISO date string (YYYY-MM-DD)
  final dayMinutes = <String, int>{};
  for (final s in sessions) {
    if (!s.state.isCompleted) continue;
    final dayKey = DateFormatters.toIsoDay(s.startedAt);
    dayMinutes[dayKey] = (dayMinutes[dayKey] ?? 0) + (s.durationSeconds / 60).round();
  }

  final now = DateTime.now();
  final todayKey = DateFormatters.toIsoDay(now);
  final todayMins = dayMinutes[todayKey] ?? 0;
  final metThresholdToday = todayMins >= threshold;

  int streak = 0;
  final streakDays = <DateTime>[];

  // If met today, count today and go backwards
  // If not met today, start checking from yesterday so streak doesn't immediately break at 8 AM
  DateTime checkDate = metThresholdToday ? now : now.subtract(const Duration(days: 1));

  while (true) {
    final key = DateFormatters.toIsoDay(checkDate);
    final mins = dayMinutes[key] ?? 0;
    if (mins >= threshold) {
      streak++;
      streakDays.add(checkDate);
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return StreakInfo(
    currentStreak: streak,
    metThresholdToday: metThresholdToday,
    minMinutesThreshold: threshold,
    streakDays: streakDays,
  );
});
