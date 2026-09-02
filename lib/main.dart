import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'app/router.dart';
import 'core/providers/timer_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/startup_service.dart';
import 'core/services/tray_service.dart';
import 'core/services/window_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize native platform services safely
  await NotificationService.instance.initialize();
  await StartupService.instance.initialize();
  await WindowService.instance.initialize(minimizeToTray: true);

  final container = ProviderContainer();

  // Setup System Tray callbacks
  await TrayService.instance.initialize(
    onOpenApp: () {
      WindowService.instance.minimize(); // restore handled inside WindowService
    },
    onTogglePause: () {
      final timerService = container.read(timerServiceProvider);
      if (timerService.snapshot.isRunning) {
        timerService.pause();
      } else if (timerService.snapshot.isPaused) {
        timerService.resume();
      }
    },
    onStartFocus: () {
      appRouter.go('/focus');
    },
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FocusFlowApp(),
    ),
  );
}
