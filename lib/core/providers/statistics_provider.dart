import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../storage/models.dart';
import '../utils/productivity_score.dart';
import 'goals_provider.dart';
import 'sessions_provider.dart';
import 'settings_provider.dart';

class DailyBarData {
  final DateTime date;
  final String dayLabel; // e.g. "Mon", "Tue"
  final int focusMinutes;

  const DailyBarData({
    required this.date,
    required this.dayLabel,
    required this.focusMinutes,
  });
}

class StatisticsData {
  final List<DailyBarData> last7DaysBars;
  final int weeklyTotalMinutes;
  final int averageSessionMinutes;
  final String bestDayInfo;
  final String mostProductiveCategory;
  final Map<String, int> categoryMinutes;
  final int totalSessions;
  final double completionRate;
  final int productivityScore;
  final int totalDistractions;

  const StatisticsData({
    required this.last7DaysBars,
    required this.weeklyTotalMinutes,
    required this.averageSessionMinutes,
    required this.bestDayInfo,
    required this.mostProductiveCategory,
    required this.categoryMinutes,
    required this.totalSessions,
    required this.completionRate,
    required this.productivityScore,
    required this.totalDistractions,
  });
}

final statisticsProvider = Provider<StatisticsData>((ref) {
  final sessionsAsync = ref.watch(sessionsProvider);
  final settings = ref.watch(settingsProvider);
  final goalProgress = ref.watch(dailyGoalProgressProvider);

  final sessions = sessionsAsync.valueOrNull ?? [];
  final now = DateTime.now();

  // 1. Last 7 Days Bars
  final last7DaysBars = <DailyBarData>[];
  final dayFormat = DateFormat('E'); // "Mon"

  for (int i = 6; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final matchingSessions = sessions.where((s) =>
        s.startedAt.year == d.year &&
        s.startedAt.month == d.month &&
        s.startedAt.day == d.day &&
        s.state.isCompleted);

    final mins = (matchingSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) / 60).round();
    last7DaysBars.add(DailyBarData(
      date: d,
      dayLabel: i == 0 ? 'Today' : dayFormat.format(d),
      focusMinutes: mins,
    ));
  }

  // 2. Weekly Total (Last 7 days total)
  final weeklyTotalMinutes = last7DaysBars.fold<int>(0, (sum, b) => sum + b.focusMinutes);

  // 3. Average Session Length
  final completedSessions = sessions.where((s) => s.state.isCompleted).toList();
  final averageSessionMinutes = completedSessions.isNotEmpty
      ? (completedSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds) / (completedSessions.length * 60)).round()
      : 0;

  // 4. Best Focus Day
  DailyBarData? bestBar;
  for (final b in last7DaysBars) {
    if (bestBar == null || b.focusMinutes > bestBar.focusMinutes) {
      bestBar = b;
    }
  }
  final bestDayInfo = (bestBar != null && bestBar.focusMinutes > 0)
      ? '${DateFormat('EEEE').format(bestBar.date)} (${bestBar.focusMinutes}m)'
      : 'No sessions yet';

  // 5. Category Minutes Breakdown
  final categoryMinutes = <String, int>{};
  for (final s in completedSessions) {
    final cat = s.categoryName;
    categoryMinutes[cat] = (categoryMinutes[cat] ?? 0) + (s.durationSeconds / 60).round();
  }

  String mostProductiveCategory = 'None';
  int maxCatMins = 0;
  categoryMinutes.forEach((cat, mins) {
    if (mins > maxCatMins) {
      maxCatMins = mins;
      mostProductiveCategory = cat;
    }
  });

  // 6. Total Sessions & Completion Rate
  final totalSessions = sessions.length;
  final completionRate = totalSessions > 0 ? (completedSessions.length / totalSessions) : 1.0;

  // 7. Total Distractions
  final totalDistractions = sessions.fold<int>(0, (sum, s) => sum + s.distractionCount);

  // 8. Productivity Score (motivational only)
  final todayDistractions = sessions
      .where((s) =>
          s.startedAt.year == now.year &&
          s.startedAt.month == now.month &&
          s.startedAt.day == now.day)
      .fold<int>(0, (sum, s) => sum + s.distractionCount);

  final todaySessionsCount = sessions
      .where((s) =>
          s.startedAt.year == now.year &&
          s.startedAt.month == now.month &&
          s.startedAt.day == now.day &&
          s.state.isCompleted)
      .length;

  final productivityScore = ProductivityScoreCalculator.calculate(
    focusMinutes: goalProgress.todayFocusMinutes,
    targetFocusMinutes: settings.dailyFocusGoalMinutes,
    completedSessions: todaySessionsCount,
    completedTasks: goalProgress.todayTasksCompleted,
    targetTasks: settings.dailyTaskGoal,
    distractionCount: todayDistractions,
  );

  return StatisticsData(
    last7DaysBars: last7DaysBars,
    weeklyTotalMinutes: weeklyTotalMinutes,
    averageSessionMinutes: averageSessionMinutes,
    bestDayInfo: bestDayInfo,
    mostProductiveCategory: mostProductiveCategory,
    categoryMinutes: categoryMinutes,
    totalSessions: totalSessions,
    completionRate: completionRate,
    productivityScore: productivityScore,
    totalDistractions: totalDistractions,
  );
});
