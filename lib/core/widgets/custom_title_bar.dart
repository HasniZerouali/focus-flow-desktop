import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/app_constants.dart';
import '../providers/timer_provider.dart';
import '../services/window_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/duration_formatters.dart';

class CustomTitleBar extends ConsumerWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final snapshot = ref.watch(timerSnapshotProvider);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // App brand & draggable header
          Expanded(
            child: DragToMoveArea(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedSm,
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.timer,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppConstants.appName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),

                    // Active session mini pill in title bar
                    if (snapshot.isActive) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: (snapshot.isRunning ? AppColors.primary : AppColors.warning).withValues(alpha: 0.15),
                          borderRadius: AppSpacing.roundedFull,
                          border: Border.all(
                            color: (snapshot.isRunning ? AppColors.primary : AppColors.warning).withValues(alpha: 0.3),
                          ),
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
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                snapshot.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ValueListenableBuilder<int>(
                              valueListenable: ref.read(timerServiceProvider).elapsedNotifier,
                              builder: (context, elapsed, _) {
                                return Text(
                                  DurationFormatters.formatHMS(elapsed, alwaysPadHours: false),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    fontFamily: 'monospace',
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Window Controls (Minimize, Maximize, Close)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WindowButton(
                icon: PhosphorIconsRegular.minus,
                tooltip: 'Minimize',
                onPressed: () => WindowService.instance.minimize(),
              ),
              _WindowButton(
                icon: PhosphorIconsRegular.cornersOut,
                tooltip: 'Maximize',
                onPressed: () => WindowService.instance.maximize(),
              ),
              _WindowButton(
                icon: PhosphorIconsRegular.x,
                tooltip: 'Close',
                isClose: true,
                onPressed: () => WindowService.instance.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color hoverColor = widget.isClose
        ? AppColors.danger
        : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated);

    Color iconColor = _isHovered && widget.isClose
        ? Colors.white
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          child: Container(
            width: 44,
            height: 40,
            color: _isHovered ? hoverColor : Colors.transparent,
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}
