import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/goals_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatters.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goalProgress = ref.watch(dailyGoalProgressProvider);
    final streak = ref.watch(streakProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goals & Habits',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build durable focus habits through daily targets and streak continuity.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  icon: const Icon(PhosphorIconsRegular.slidersHorizontal, size: 16),
                  label: const Text('Edit Targets'),
                  onPressed: () => _showGoalEditDialog(context, ref, settings),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Streak Showcase Banner
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF311042)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFFDF2F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppSpacing.roundedXl,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 42)),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${streak.currentStreak} Day Focus Streak',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                            if (streak.metThresholdToday) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: AppSpacing.roundedFull,
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(PhosphorIconsFill.check, size: 12, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text('ACTIVE TODAY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          streak.metThresholdToday
                              ? 'Awesome! You met your minimum ${streak.minMinutesThreshold} minutes today.'
                              : 'Log at least ${streak.minMinutesThreshold} minutes of focus today to extend your streak!',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // CELEBRATORY BANNER IF ALL GOALS REACHED
            if (goalProgress.isAllGoalsHit)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(color: AppColors.success, width: 1.5),
                ),
                child: const Row(
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Daily Goals Achieved!',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.success),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You crushed both your focus time and daily task completion targets today. Outstanding work!',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Target Cards: Daily Focus, Weekly Focus, Daily Tasks
            _buildGoalCard(
              title: 'Daily Focus Goal',
              icon: PhosphorIconsRegular.timer,
              iconColor: AppColors.primary,
              currentValue: '${goalProgress.todayFocusMinutes} min',
              targetValue: '${goalProgress.targetFocusMinutes} min',
              progress: goalProgress.focusProgress,
              isAchieved: goalProgress.isFocusGoalHit,
              subtitle: '${goalProgress.todayFocusMinutes}m completed today (${DurationFormatters.formatHoursMinutes((goalProgress.targetFocusMinutes - goalProgress.todayFocusMinutes) * 60)} remaining)',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildGoalCard(
              title: 'Weekly Focus Goal',
              icon: PhosphorIconsRegular.chartBar,
              iconColor: AppColors.info,
              currentValue: '${goalProgress.todayFocusMinutes} min',
              targetValue: '${settings.weeklyFocusGoalMinutes} min',
              progress: (goalProgress.todayFocusMinutes / (settings.weeklyFocusGoalMinutes > 0 ? settings.weeklyFocusGoalMinutes : 600)).clamp(0.0, 1.0),
              isAchieved: goalProgress.todayFocusMinutes >= settings.weeklyFocusGoalMinutes,
              subtitle: 'Cumulative focus towards your weekly master target',
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            _buildGoalCard(
              title: 'Daily Task Completion Goal',
              icon: PhosphorIconsRegular.checkSquare,
              iconColor: AppColors.success,
              currentValue: '${goalProgress.todayTasksCompleted} tasks',
              targetValue: '${goalProgress.targetTasksCompleted} tasks',
              progress: goalProgress.tasksProgress,
              isAchieved: goalProgress.isTaskGoalHit,
              subtitle: '${goalProgress.todayTasksCompleted} of ${goalProgress.targetTasksCompleted} tasks finished today',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String currentValue,
    required String targetValue,
    required double progress,
    required bool isAchieved,
    required String subtitle,
    required bool isDark,
  }) {
    final pct = (progress * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: Icon(icon, size: 20, color: iconColor),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '$currentValue / $targetValue',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'monospace'),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAchieved ? AppColors.success.withValues(alpha: 0.15) : iconColor.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Text(
                        isAchieved ? 'DONE! ($pct%)' : '$pct%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAchieved ? AppColors.success : iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: AppSpacing.roundedFull,
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(isAchieved ? AppColors.success : iconColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalEditDialog(BuildContext context, WidgetRef ref, dynamic settings) {
    int dailyMins = settings.dailyFocusGoalMinutes;
    int weeklyMins = settings.weeklyFocusGoalMinutes;
    int taskCount = settings.dailyTaskGoal;
    int streakThreshold = settings.streakMinMinutes;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Customize Goals & Streak Threshold'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSlider(
                  'Daily Focus Goal',
                  '$dailyMins min',
                  dailyMins.toDouble(),
                  30,
                  360,
                  11,
                  (v) => setDlgState(() => dailyMins = v.round()),
                ),
                _buildSlider(
                  'Weekly Focus Goal',
                  '${weeklyMins ~/ 60} hrs (${weeklyMins}m)',
                  weeklyMins.toDouble(),
                  120,
                  2400,
                  19,
                  (v) => setDlgState(() => weeklyMins = v.round()),
                ),
                _buildSlider(
                  'Daily Task Target',
                  '$taskCount tasks',
                  taskCount.toDouble(),
                  1,
                  10,
                  9,
                  (v) => setDlgState(() => taskCount = v.round()),
                ),
                _buildSlider(
                  'Streak Min Focus',
                  '$streakThreshold min/day',
                  streakThreshold.toDouble(),
                  10,
                  60,
                  5,
                  (v) => setDlgState(() => streakThreshold = v.round()),
                ),
              ],
            ),
            actions: [
              OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(
                          dailyFocusGoalMinutes: dailyMins,
                          weeklyFocusGoalMinutes: weeklyMins,
                          dailyTaskGoal: taskCount,
                          streakMinMinutes: streakThreshold,
                        ),
                      );
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save Targets'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlider(String title, String valStr, double value, double min, double max, int divisions, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(valStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
