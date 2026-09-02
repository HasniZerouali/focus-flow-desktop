import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timer_desktop/core/services/focus_timer_service.dart';
import 'package:timer_desktop/core/theme/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../core/storage/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/duration_formatters.dart';
import 'widgets/distraction_sheet.dart';
import 'widgets/minimal_focus_view.dart';
import 'widgets/session_completion_sheet.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  bool _isMinimalMode = false;

  // New session config fields (when idle)
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'Development';
  String? _selectedTaskId;
  TimerMode _selectedMode = TimerMode.free;
  int _countdownMinutes = 25;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startSession() {
    final title = _titleController.text.trim();
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

    final tasks = ref.read(tasksProvider).valueOrNull ?? [];
    final selectedTask = _selectedTaskId != null
        ? tasks.where((t) => t.id == _selectedTaskId).firstOrNull
        : null;

    ref.read(timerServiceProvider).startSession(
          title: title.isEmpty ? (selectedTask?.title ?? 'Focused Work') : title,
          categoryId: category.id,
          categoryName: category.name,
          taskId: selectedTask?.id,
          taskTitle: selectedTask?.title,
          mode: _selectedMode,
          targetDurationMinutes: _countdownMinutes,
        );

    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final snapshot = ref.watch(timerSnapshotProvider);
    final timerService = ref.watch(timerServiceProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final activeTasks = tasks.where((t) => !t.completed).toList();

    // If minimal mode is active and session is running
    if (_isMinimalMode && snapshot.isActive) {
      return MinimalFocusView(
        onExitMinimal: () => setState(() => _isMinimalMode = false),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: snapshot.isActive
                ? _buildActiveSessionView(context, snapshot, timerService, isDark)
                : _buildNewSessionSetup(context, categories, activeTasks, isDark),
          ),
        ),
      ),
    );
  }

  // --- VIEW WHEN SESSION IS ACTIVE ---
  Widget _buildActiveSessionView(
    BuildContext context,
    TimerSnapshot snapshot,
    FocusTimerService timerService,
    bool isDark,
  ) {
    final catColor = AppColors.getCategoryColor(snapshot.categoryName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Toolbar (Mode label, Minimal Mode button)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (snapshot.isRunning ? AppColors.primary : AppColors.warning).withValues(alpha: 0.15),
                borderRadius: AppSpacing.roundedFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: snapshot.isRunning ? AppColors.primary : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    snapshot.isRunning ? 'SESSION IN PROGRESS' : 'SESSION PAUSED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: snapshot.isRunning ? AppColors.primary : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(PhosphorIconsRegular.cornersOut, size: 16),
              label: const Text('Minimal Mode'),
              onPressed: () => setState(() => _isMinimalMode = true),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Session Title & Category Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.15),
            borderRadius: AppSpacing.roundedFull,
            border: Border.all(color: catColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            snapshot.categoryName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: catColor),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          snapshot.title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        if (snapshot.taskTitle != null) ...[
          const SizedBox(height: 6),
          Text(
            'Task: ${snapshot.taskTitle}',
            style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ],

        const SizedBox(height: 48),

        // Prominent Timer Display
        ValueListenableBuilder<int>(
          valueListenable: timerService.elapsedNotifier,
          builder: (context, elapsed, _) {
            final isFree = snapshot.mode == TimerMode.free;
            final remaining = snapshot.targetDurationSeconds - elapsed;
            final display = isFree ? DurationFormatters.formatHMS(elapsed) : DurationFormatters.formatHMS(remaining > 0 ? remaining : 0);

            return Column(
              children: [
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 84,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 3.0,
                    color: snapshot.isRunning ? (isDark ? Colors.white : AppColors.lightTextPrimary) : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFree
                      ? 'Free Focus (Stopwatch)'
                      : 'Target: ${snapshot.targetDurationSeconds ~/ 60} minutes (${remaining > 0 ? DurationFormatters.formatHoursMinutes(remaining) : "0m"} remaining)',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 48),

        // Controls: Pause, Distraction, Finish, Cancel
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: snapshot.isRunning ? AppColors.primary : AppColors.warning,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
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
                size: 20,
              ),
              label: Text(
                snapshot.isRunning ? 'PAUSE' : 'RESUME',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
              onPressed: () => DistractionSheet.show(context),
              icon: const Icon(PhosphorIconsRegular.warningCircle, size: 18, color: AppColors.warning),
              label: Text(
                '+ Distraction (${snapshot.distractionCount})',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
              ),
              onPressed: () => SessionCompletionSheet.show(context),
              icon: const Icon(PhosphorIconsFill.check, size: 20),
              label: const Text(
                'FINISH',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
              ),
            ),
          ],
        ),

        const SizedBox(height: 48),

        // Quick Session Notes
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Session Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (snapshot.notes.isNotEmpty)
                      const Text('Saved', style: TextStyle(fontSize: 11, color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  onChanged: (val) => timerService.updateNotes(val),
                  decoration: const InputDecoration(
                    hintText: 'Jot down quick thoughts, findings, or tasks while focused...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- VIEW WHEN NO SESSION IS RUNNING (SETUP) ---
  Widget _buildNewSessionSetup(
    BuildContext context,
    List<CategoryModel> categories,
    List<TaskModel> tasks,
    bool isDark,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.roundedSm,
                  ),
                  child: const Icon(PhosphorIconsRegular.timer, size: 24, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start a Focus Session',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Choose a mode, pick a category, and dive into distraction-free work.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Mode Selector: Free Focus vs Countdown
            const Text('Focus Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ModeSelectorCard(
                    title: 'Free Focus',
                    subtitle: 'Open-ended stopwatch timer',
                    icon: PhosphorIconsRegular.timer,
                    isSelected: _selectedMode == TimerMode.free,
                    onTap: () => setState(() => _selectedMode = TimerMode.free),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ModeSelectorCard(
                    title: 'Countdown',
                    subtitle: 'Timed sprint with countdown alert',
                    icon: PhosphorIconsRegular.clockCountdown,
                    isSelected: _selectedMode == TimerMode.countdown,
                    onTap: () => setState(() => _selectedMode = TimerMode.countdown),
                  ),
                ),
              ],
            ),

            // Countdown Presets if Countdown mode selected
            if (_selectedMode == TimerMode.countdown) ...[
              const SizedBox(height: 24),
              const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: AppConstants.countdownPresets.map((mins) {
                  final isSelected = _countdownMinutes == mins;
                  return ChoiceChip(
                    label: Text('$mins min'),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _countdownMinutes = mins);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 28),

            // Session Title Input
            const Text('What are you working on?', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Implement Riverpod timer providers, Read Chapter 4...',
                prefixIcon: Icon(PhosphorIconsRegular.pencilSimple, size: 18),
              ),
            ),

            const SizedBox(height: 24),

            // Category & Task Linking
            Row(
              children: [
                // Category Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: categories.any((c) => c.name == _selectedCategory)
                                ? _selectedCategory
                                : (categories.isNotEmpty ? categories.first.name : 'Development'),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                            items: categories.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.name,
                                child: Text(c.name),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Link to Task (optional)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Link to Task (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                          borderRadius: AppSpacing.roundedMd,
                          border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value: _selectedTaskId,
                            hint: const Text('None (Standalone Session)', style: TextStyle(fontSize: 13)),
                            onChanged: (val) => setState(() => _selectedTaskId = val),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('None (Standalone Session)'),
                              ),
                              ...tasks.map((t) {
                                return DropdownMenuItem<String?>(
                                  value: t.id,
                                  child: Text(t.title, overflow: TextOverflow.ellipsis),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            // START BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                ),
                onPressed: _startSession,
                icon: const Icon(PhosphorIconsFill.play, size: 18),
                label: const Text(
                  'START FOCUS SESSION',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelectorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeSelectorCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: AppSpacing.roundedMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.1) : Colors.transparent,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}
