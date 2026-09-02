import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/custom_title_bar.dart';
import '../core/widgets/sidebar_navigation.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/focus/presentation/focus_screen.dart';
import '../features/goals/presentation/goals_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/pomodoro/presentation/pomodoro_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) {
        return _AppShellLayout(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/focus',
          pageBuilder: (context, state) => const NoTransitionPage(child: FocusScreen()),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) => const NoTransitionPage(child: TasksScreen()),
        ),
        GoRoute(
          path: '/pomodoro',
          pageBuilder: (context, state) => const NoTransitionPage(child: PomodoroScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/statistics',
          pageBuilder: (context, state) => const NoTransitionPage(child: StatisticsScreen()),
        ),
        GoRoute(
          path: '/goals',
          pageBuilder: (context, state) => const NoTransitionPage(child: GoalsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);

class _AppShellLayout extends StatefulWidget {
  final String currentPath;
  final Widget child;

  const _AppShellLayout({
    required this.currentPath,
    required this.child,
  });

  @override
  State<_AppShellLayout> createState() => _AppShellLayoutState();
}

class _AppShellLayoutState extends State<_AppShellLayout> {
  bool _isManuallyCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final autoCollapse = constraints.maxWidth < 1200;
        final isCollapsed = _isManuallyCollapsed || autoCollapse;

        return Scaffold(
          body: Column(
            children: [
              // 1. Windows Custom Draggable Titlebar
              const CustomTitleBar(),

              // 2. Main Content Area with Left Sidebar
              Expanded(
                child: Row(
                  children: [
                    SidebarNavigation(
                      currentRoute: widget.currentPath,
                      isCollapsed: isCollapsed,
                      onToggleCollapse: () {
                        setState(() => _isManuallyCollapsed = !_isManuallyCollapsed);
                      },
                    ),
                    Expanded(
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
