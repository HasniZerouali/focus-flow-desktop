import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/timer_provider.dart';
import '../core/theme/app_theme.dart';
import '../features/focus/presentation/widgets/session_completion_sheet.dart';
import 'router.dart';

class FocusFlowApp extends ConsumerStatefulWidget {
  const FocusFlowApp({super.key});

  @override
  ConsumerState<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends ConsumerState<FocusFlowApp> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyboard);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyboard);
    super.dispose();
  }

  bool _handleGlobalKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    if (!isCtrl || !isShift) return false;

    final key = event.logicalKey;
    final timerService = ref.read(timerServiceProvider);
    final snapshot = timerService.snapshot;

    // Ctrl + Shift + S -> Toggle Start / Pause / Resume
    if (key == LogicalKeyboardKey.keyS) {
      if (snapshot.isRunning) {
        timerService.pause();
      } else if (snapshot.isPaused) {
        timerService.resume();
      } else {
        appRouter.go('/focus');
      }
      return true;
    }

    // Ctrl + Shift + F -> Finish Focus
    if (key == LogicalKeyboardKey.keyF) {
      if (snapshot.isActive) {
        final navContext = rootNavigatorKey.currentContext;
        if (navContext != null) {
          SessionCompletionSheet.show(navContext);
        }
      }
      return true;
    }

    // Ctrl + Shift + P -> Go to Pomodoro
    if (key == LogicalKeyboardKey.keyP) {
      appRouter.go('/pomodoro');
      return true;
    }

    // Ctrl + Shift + T -> Go to Tasks
    if (key == LogicalKeyboardKey.keyT) {
      appRouter.go('/tasks');
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settingsNotifier = ref.watch(settingsProvider.notifier);

    return MaterialApp.router(
      title: 'Focus Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsNotifier.flutterThemeMode,
      routerConfig: appRouter,
    );
  }
}
