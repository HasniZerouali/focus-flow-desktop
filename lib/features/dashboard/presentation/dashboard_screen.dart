import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/goals_provider.dart';
import '../../../core/providers/sessions_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../core/services/focus_timer_service.dart';
import '../../../core/storage/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/duration_formatters.dart';
import '../../../core/widgets/stat_card.dart';
import '../../focus/presentation/widgets/session_completion_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _focusInputController = TextEditingController();
  String _selectedCategory = 'Development';

  @override
  void dispose() {
    _focusInputController.dispose();
    super.dispose();
  }

  void _startQuickFocus() {
    final title = _focusInputController.text.trim();
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final category = categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => const CategoryModel(
        id: 'Development',
        name: 'Development',
        colorHex: '6366F1',
        iconName: 'code',
      ),
    );

    ref.read(timerServiceProvider).startSession(
          title: title.isEmpty ? 'Quick Focus' : title,
          categoryId: category.id,
          categoryName: category.name,
          mode: TimerMode.free,
        );

    _focusInputController.clear();
    context.go('/focus');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final timerSnapshot = ref.watch(timerSnapshotProvider);
    final goalProgress = ref.watch(dailyGoalProgressProvider);
    final streak = ref.watch(streakProvider);
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
    final todaySessions = sessions.where((s) => DateFormatters.isToday(s.startedAt) && s.state.isCompleted).toList();
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Greeting & Today Focus summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatters.greeting(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to achieve your goals?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.calendar, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatters.formatFullDate(DateTime.now()),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. ACTIVE SESSION LIVE CARD (If active) OR INLINE QUICK START FORM (If idle)
            if (timerSnapshot.isActive)
              _ActiveSessionBanner(snapshot: timerSnapshot)
            else
              _QuickStartCard(
                inputController: _focusInputController,
                selectedCategory: _selectedCategory,
                categories: categories,
                onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
                onStart: _startQuickFocus,
              ),

            const SizedBox(height: 28),

            // 3. STAT CARDS (4 cards: Focus Today, Sessions, Tasks, Streak)
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth.clamp(220, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.timer,
                        iconColor: AppColors.primary,
                        title: "Today's Focus Time",
                        value: DurationFormatters.formatHoursMinutes(goalProgress.todayFocusMinutes * 60),
                        subtitle: 'Goal: ${DurationFormatters.formatHoursMinutes(goalProgress.targetFocusMinutes * 60)}',
                        onTap: () => context.go('/history'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth.clamp(220, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.checkCircle,
                        iconColor: AppColors.success,
                        title: 'Completed Sessions',
                        value: '${todaySessions.length}',
                        subtitle: '${todaySessions.length} focus sprints',
                        onTap: () => context.go('/history'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth.clamp(220, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.checkSquare,
                        iconColor: AppColors.info,
                        title: 'Tasks Finished',
                        value: '${goalProgress.todayTasksCompleted}',
                        subtitle: 'Target: ${goalProgress.targetTasksCompleted} tasks',
                        onTap: () => context.go('/tasks'),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth.clamp(220, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.fire,
                        iconColor: AppColors.warning,
                        title: 'Current Streak',
                        value: '🔥 ${streak.currentStreak} Days',
                        subtitle: streak.metThresholdToday ? 'Goal reached today!' : 'Keep it going today!',
                        onTap: () => context.go('/goals'),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // 4. DAILY GOAL PROGRESS BAR
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: const Icon(PhosphorIconsRegular.target, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Daily Focus Goal',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${goalProgress.todayFocusMinutes} of ${goalProgress.targetFocusMinutes} minutes completed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '${(goalProgress.focusProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: goalProgress.isFocusGoalHit ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: AppSpacing.roundedFull,
                      child: LinearProgressIndicator(
                        value: goalProgress.focusProgress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          goalProgress.isFocusGoalHit ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 5. TODAY'S SESSIONS PREVIEW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Activity",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/history'),
                  icon: const Icon(PhosphorIconsRegular.arrowRight, size: 14),
                  label: const Text('View Full History'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (todaySessions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          PhosphorIconsRegular.hourglassLow,
                          size: 32,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No focus sessions recorded today yet',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type what you want to work on above and click START FOCUS',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todaySessions.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final s = todaySessions[index];
                  final catColor = AppColors.getCategoryColor(s.categoryName);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.categoryName} • ${DateFormatters.formatTime(s.startedAt)} - ${DateFormatters.formatTime(s.endedAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DurationFormatters.formatDetailed(s.durationSeconds),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final TextEditingController inputController;
  final String selectedCategory;
  final List<CategoryModel> categories;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onStart;

  const _QuickStartCard({
    required this.inputController,
    required this.selectedCategory,
    required this.categories,
    required this.onCategoryChanged,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.roundedSm,
                ),
                child: const Icon(PhosphorIconsRegular.lightning, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              const Text(
                'What do you want to focus on right now?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: inputController,
                  onSubmitted: (_) => onStart(),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Build Flutter Authentication, Study Chapter 3...',
                    prefixIcon: Icon(PhosphorIconsRegular.pencilSimple, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: categories.any((c) => c.name == selectedCategory)
                          ? selectedCategory
                          : (categories.isNotEmpty ? categories.first.name : 'Development'),
                      icon: const Icon(PhosphorIconsRegular.caretDown, size: 16),
                      onChanged: (val) {
                        if (val != null) onCategoryChanged(val);
                      },
                      items: categories.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.name,
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.getCategoryColor(c.name),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                ),
                onPressed: onStart,
                icon: const Icon(PhosphorIconsFill.play, size: 16),
                label: const Text('START FOCUS', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends ConsumerWidget {
  final TimerSnapshot snapshot;

  const _ActiveSessionBanner({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timerService = ref.watch(timerServiceProvider);
    final catColor = AppColors.getCategoryColor(snapshot.categoryName);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
        borderRadius: AppSpacing.roundedXl,
        border: Border.all(
          color: snapshot.isRunning ? AppColors.primary : AppColors.warning,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (snapshot.isRunning ? AppColors.primary : AppColors.warning).withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (snapshot.isRunning ? AppColors.primary : AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: snapshot.isRunning ? AppColors.primary : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            snapshot.isRunning ? 'FOCUS SESSION RUNNING' : 'SESSION PAUSED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: snapshot.isRunning ? AppColors.primary : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedFull,
                      ),
                      child: Text(
                        snapshot.categoryName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  snapshot.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                if (snapshot.taskTitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Linked to: ${snapshot.taskTitle}',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                ],
              ],
            ),
          ),

          // Live Timer Display & Controls
          Row(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: timerService.elapsedNotifier,
                builder: (context, elapsed, _) {
                  final display = snapshot.mode == TimerMode.free
                      ? DurationFormatters.formatHMS(elapsed)
                      : DurationFormatters.formatHMS(
                          snapshot.targetDurationSeconds - elapsed > 0 ? snapshot.targetDurationSeconds - elapsed : 0);

                  return Text(
                    display,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      letterSpacing: 1.0,
                      color: snapshot.isRunning ? AppColors.primary : AppColors.warning,
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: () {
                  if (snapshot.isRunning) {
                    timerService.pause();
                  } else {
                    timerService.resume();
                  }
                },
                icon: Icon(
                  snapshot.isRunning ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
                  size: 16,
                ),
                label: Text(snapshot.isRunning ? 'Pause' : 'Resume'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: () async {
                  await SessionCompletionSheet.show(context);
                  ref.invalidate(sessionsProvider);
                  ref.invalidate(tasksProvider);
                },
                icon: const Icon(PhosphorIconsFill.check, size: 16),
                label: const Text('Finish', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Open Focus Screen',
                icon: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 20),
                onPressed: () => context.go('/focus'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
