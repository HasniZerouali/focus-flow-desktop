import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/sessions_provider.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../core/providers/timer_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_formatters.dart';

class SessionCompletionSheet extends ConsumerStatefulWidget {
  const SessionCompletionSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const SessionCompletionSheet(),
    );
  }

  @override
  ConsumerState<SessionCompletionSheet> createState() => _SessionCompletionSheetState();
}

class _SessionCompletionSheetState extends ConsumerState<SessionCompletionSheet> {
  int _rating = 4; // default 4 stars
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final snapshot = ref.read(timerSnapshotProvider);
    _notesController.text = snapshot.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final timerService = ref.read(timerServiceProvider);
    await timerService.finishSession(
      rating: _rating,
      notes: _notesController.text.trim(),
    );

    // Invalidate sessions list and tasks to trigger UI update
    ref.invalidate(sessionsProvider);
    ref.invalidate(tasksProvider);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Focus session saved to history!'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          width: 320,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final snapshot = ref.watch(timerSnapshotProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsFill.checkCircle, size: 24, color: AppColors.success),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Completed!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        snapshot.title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Duration & Stats banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                  borderRadius: AppSpacing.roundedLg,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      label: 'Total Duration',
                      value: DurationFormatters.formatHMS(snapshot.elapsedSeconds),
                      color: AppColors.primary,
                    ),
                    Container(height: 36, width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _StatColumn(
                      label: 'Pauses',
                      value: '${snapshot.pauseCount}',
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    Container(height: 36, width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _StatColumn(
                      label: 'Distractions',
                      value: '${snapshot.distractionCount}',
                      color: snapshot.distractionCount > 0 ? AppColors.warning : AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1-5 Rating
              const Text('Focus Quality Rating', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  final isFilled = starNum <= _rating;
                  return IconButton(
                    iconSize: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      isFilled ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                      color: isFilled ? AppColors.warning : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                    onPressed: () => setState(() => _rating = starNum),
                  );
                }),
              ),
              const SizedBox(height: 18),

              // Notes
              const Text('Notes & Reflections (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'What did you accomplish? Any roadblocks to note?',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel / Keep Running'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _save,
                    child: const Text('Save to History', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
