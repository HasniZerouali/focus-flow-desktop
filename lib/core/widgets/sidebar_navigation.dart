import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/goals_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/timer_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class NavItemData {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavItemData({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class SidebarNavigation extends ConsumerStatefulWidget {
  final String currentRoute;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const SidebarNavigation({
    super.key,
    required this.currentRoute,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  ConsumerState<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends ConsumerState<SidebarNavigation> {
  static const List<NavItemData> _navItems = [
    NavItemData(
      path: '/dashboard',
      label: 'Dashboard',
      icon: PhosphorIconsRegular.squaresFour,
      activeIcon: PhosphorIconsFill.squaresFour,
    ),
    NavItemData(
      path: '/focus',
      label: 'Focus',
      icon: PhosphorIconsRegular.timer,
      activeIcon: PhosphorIconsFill.timer,
    ),
    NavItemData(
      path: '/tasks',
      label: 'Tasks',
      icon: PhosphorIconsRegular.checkSquare,
      activeIcon: PhosphorIconsFill.checkSquare,
    ),
    NavItemData(
      path: '/pomodoro',
      label: 'Pomodoro',
      icon: PhosphorIconsRegular.clockCountdown,
      activeIcon: PhosphorIconsFill.clockCountdown,
    ),
    NavItemData(
      path: '/history',
      label: 'History',
      icon: PhosphorIconsRegular.clockCounterClockwise,
      activeIcon: PhosphorIconsFill.clockCounterClockwise,
    ),
    NavItemData(
      path: '/statistics',
      label: 'Statistics',
      icon: PhosphorIconsRegular.chartBar,
      activeIcon: PhosphorIconsFill.chartBar,
    ),
    NavItemData(
      path: '/goals',
      label: 'Goals',
      icon: PhosphorIconsRegular.target,
      activeIcon: PhosphorIconsFill.target,
    ),
    NavItemData(
      path: '/settings',
      label: 'Settings',
      icon: PhosphorIconsRegular.gear,
      activeIcon: PhosphorIconsFill.gear,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = widget.isCollapsed ? 68.0 : 220.0;

    final timerSnapshot = ref.watch(timerSnapshotProvider);
    final streakInfo = ref.watch(streakProvider);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final uncompletedTasks = tasks.where((t) => !t.completed).length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = widget.currentRoute.startsWith(item.path);

                Widget? badge;
                if (item.path == '/focus' && timerSnapshot.isActive) {
                  badge = Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: timerSnapshot.isRunning ? AppColors.primary : AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  );
                } else if (item.path == '/tasks' && uncompletedTasks > 0) {
                  badge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Text(
                      '$uncompletedTasks',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  );
                } else if (item.path == '/goals' && streakInfo.currentStreak > 0) {
                  badge = Text(
                    '🔥${streakInfo.currentStreak}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  );
                }

                return _NavItemTile(
                  item: item,
                  isActive: isActive,
                  isCollapsed: widget.isCollapsed,
                  badge: badge,
                  onTap: () => context.go(item.path),
                );
              },
            ),
          ),

          // Bottom collapse toggle button
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: AppSpacing.roundedMd,
              onTap: widget.onToggleCollapse,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Row(
                  mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(
                      widget.isCollapsed
                          ? PhosphorIconsRegular.caretDoubleRight
                          : PhosphorIconsRegular.caretDoubleLeft,
                      size: 16,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Collapse sidebar',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemTile extends StatefulWidget {
  final NavItemData item;
  final bool isActive;
  final bool isCollapsed;
  final Widget? badge;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    this.badge,
    required this.onTap,
  });

  @override
  State<_NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<_NavItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor = Colors.transparent;
    if (widget.isActive) {
      bgColor = AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.12);
    } else if (_isHovered) {
      bgColor = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated;
    }

    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final itemColor = widget.isActive ? activeColor : inactiveColor;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCollapsed ? 12 : 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.roundedMd,
      ),
      child: Row(
        mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            widget.isActive ? widget.item.activeIcon : widget.item.icon,
            size: 20,
            color: itemColor,
          ),
          if (!widget.isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isActive
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                      : itemColor,
                ),
              ),
            ),
            if (widget.badge != null) widget.badge!,
          ],
        ],
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: widget.item.label,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: InkWell(
            borderRadius: AppSpacing.roundedMd,
            onTap: widget.onTap,
            child: content,
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}
