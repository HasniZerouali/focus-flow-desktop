import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/timer_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/duration_formatters.dart';
import '../../domain/timer_mode.dart';
import 'distraction_sheet.dart';
import 'session_completion_sheet.dart';

class MinimalFocusView extends ConsumerWidget {
  final VoidCallback onExitMinimal;

  const MinimalFocusView({
    super.key,
    required this.onExitMinimal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final snapshot = ref.watch(timerSnapshotProvider);
    final timerService = ref.watch(timerServiceProvider);
    final catColor = AppColors.getCategoryColor(snapshot.categoryName);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // Exit button top-right
          Positioned(
            top: 24,
            right: 24,
            child: Tooltip(
              message: 'Exit Minimal Mode',
              child: IconButton(
                icon: const Icon(PhosphorIconsRegular.cornersIn, size: 22),
                onPressed: onExitMinimal,
              ),
            ),
          ),

          // Central focus elements
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.roundedFull,
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    snapshot.categoryName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: catColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Task Title
                Text(
                  snapshot.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 36),

                // Enormous Timer
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
                        fontSize: 92,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 2.0,
                        color: snapshot.isRunning ? (isDark ? Colors.white : AppColors.lightTextPrimary) : AppColors.warning,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),

                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        size: 18,
                      ),
                      label: Text(
                        snapshot.isRunning ? 'Pause' : 'Resume',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      tooltip: 'Log Distraction',
                      icon: const Icon(PhosphorIconsRegular.warningCircle, size: 22),
                      onPressed: () => DistractionSheet.show(context),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                      ),
                      onPressed: () => SessionCompletionSheet.show(context),
                      icon: const Icon(PhosphorIconsFill.check, size: 18),
                      label: const Text(
                        'Finish Session',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
