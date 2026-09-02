import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatters.dart';
import '../../focus/domain/timer_mode.dart';
import '../domain/pomodoro_phase.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  int _currentCycle = 1;

  void _startPomodoro() {
    final settings = ref.read(settingsProvider);
    final duration = _getPhaseMinutes(settings);

    ref.read(timerServiceProvider).startSession(
          title: 'Pomodoro ${_currentPhase.label}',
          categoryId: 'Development',
          categoryName: 'Development',
          mode: TimerMode.pomodoro,
          targetDurationMinutes: duration,
          pomodoroCycle: _currentCycle,
          pomodoroPhase: _currentPhase,
        );
  }

  int _getPhaseMinutes(dynamic settings) {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return settings.defaultFocusMinutes;
      case PomodoroPhase.shortBreak:
        return settings.defaultShortBreakMinutes;
      case PomodoroPhase.longBreak:
        return settings.defaultLongBreakMinutes;
    }
  }

  void _skipToNextPhase() {
    final settings = ref.read(settingsProvider);
    final totalCycles = settings.pomodoroCycles;

    if (_currentPhase == PomodoroPhase.work) {
      if (_currentCycle >= totalCycles) {
        _currentPhase = PomodoroPhase.longBreak;
      } else {
        _currentPhase = PomodoroPhase.shortBreak;
      }
    } else {
      if (_currentPhase == PomodoroPhase.longBreak) {
        _currentCycle = 1;
      } else {
        _currentCycle++;
      }
      _currentPhase = PomodoroPhase.work;
    }

    ref.read(timerServiceProvider).cancelSession();
    setState(() {});
  }

  void _resetCycle() {
    ref.read(timerServiceProvider).cancelSession();
    setState(() {
      _currentPhase = PomodoroPhase.work;
      _currentCycle = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final snapshot = ref.watch(timerSnapshotProvider);
    final timerService = ref.watch(timerServiceProvider);

    final isPomodoroActive = snapshot.isActive && snapshot.mode == TimerMode.pomodoro;
    final totalCycles = settings.pomodoroCycles;
    final phaseColor = _currentPhase.color;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pomodoro Focus',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Work in focused sprints with structured restorative breaks.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Configure Intervals',
                      icon: const Icon(PhosphorIconsRegular.slidersHorizontal, size: 20),
                      onPressed: () => _showSettingsDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Phase Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.15),
                    borderRadius: AppSpacing.roundedFull,
                    border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentPhase.isWork ? PhosphorIconsFill.brain : PhosphorIconsFill.coffee,
                        size: 16,
                        color: phaseColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentPhase.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: phaseColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Session dots (e.g. Session 2 of 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Session $_currentCycle of $totalCycles',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: List.generate(totalCycles, (index) {
                        final isDoneOrCurrent = index < _currentCycle;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDoneOrCurrent
                                ? phaseColor
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Circular Progress Ring with Timer
                ValueListenableBuilder<int>(
                  valueListenable: timerService.elapsedNotifier,
                  builder: (context, elapsed, _) {
                    final targetSeconds = isPomodoroActive
                        ? snapshot.targetDurationSeconds
                        : (_getPhaseMinutes(settings) * 60);

                    final remaining = isPomodoroActive ? (targetSeconds - elapsed) : targetSeconds;
                    final progress = targetSeconds > 0 ? (elapsed / targetSeconds).clamp(0.0, 1.0) : 0.0;

                    return SizedBox(
                      width: 260,
                      height: 260,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(260, 260),
                            painter: _CircleProgressPainter(
                              progress: isPomodoroActive ? progress : 0.0,
                              color: phaseColor,
                              bgColor: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceElevated,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DurationFormatters.formatHMS(remaining > 0 ? remaining : 0, alwaysPadHours: false),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isPomodoroActive
                                    ? (snapshot.isRunning ? 'Focusing' : 'Paused')
                                    : 'Ready to begin',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isPomodoroActive)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: phaseColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                        ),
                        onPressed: _startPomodoro,
                        icon: const Icon(PhosphorIconsFill.play, size: 18),
                        label: Text(
                          'START ${_currentPhase.isWork ? "WORK" : "BREAK"}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
                        ),
                      )
                    else ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: snapshot.isRunning ? AppColors.primary : AppColors.warning,
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                        ),
                        onPressed: () {
                          if (snapshot.isRunning) {
                            timerService.pause();
                          } else {
                            timerService.resume();
                          }
                        },
                        icon: Icon(snapshot.isRunning ? PhosphorIconsFill.pause : PhosphorIconsFill.play, size: 18),
                        label: Text(snapshot.isRunning ? 'PAUSE' : 'RESUME', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedMd),
                        ),
                        onPressed: _skipToNextPhase,
                        icon: const Icon(PhosphorIconsRegular.skipForward, size: 18),
                        label: const Text('Skip Phase'),
                      ),
                    ],
                    const SizedBox(width: 14),
                    IconButton(
                      tooltip: 'Reset Cycle',
                      icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 20),
                      onPressed: _resetCycle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final settings = ref.read(settingsProvider);
    int focus = settings.defaultFocusMinutes;
    int shortBreak = settings.defaultShortBreakMinutes;
    int longBreak = settings.defaultLongBreakMinutes;
    int cycles = settings.pomodoroCycles;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: const Text('Pomodoro Interval Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSliderTile('Focus Duration', focus, 10, 60, (v) => setDlgState(() => focus = v.round())),
                _buildSliderTile('Short Break', shortBreak, 1, 15, (v) => setDlgState(() => shortBreak = v.round())),
                _buildSliderTile('Long Break', longBreak, 5, 30, (v) => setDlgState(() => longBreak = v.round())),
                _buildSliderTile('Sessions per Cycle', cycles, 2, 8, (v) => setDlgState(() => cycles = v.round())),
              ],
            ),
            actions: [
              OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(
                          defaultFocusMinutes: focus,
                          defaultShortBreakMinutes: shortBreak,
                          defaultLongBreakMinutes: longBreak,
                          pomodoroCycles: cycles,
                        ),
                      );
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliderTile(String title, int value, int min, int max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
            Text('$value min', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;

    // Background track
    final bgPaint = Paint()
      ..color = bgColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Active progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
