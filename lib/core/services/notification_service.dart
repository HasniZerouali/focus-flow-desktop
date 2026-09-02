import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await localNotifier.setup(
          appName: 'Focus Flow',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to initialize local_notifier: $e');
      }
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    bool silent = false,
  }) async {
    if (!_initialized) return;
    try {
      final notification = LocalNotification(
        title: title,
        body: body,
        silent: silent,
      );
      await notification.show();
    } catch (e) {
      debugPrint('Error displaying notification: $e');
    }
  }

  Future<void> notifySessionCompleted({
    required String sessionTitle,
    required int durationMinutes,
    bool enabled = true,
  }) async {
    if (!enabled) return;
    await showNotification(
      title: '🎯 Focus Session Complete!',
      body: 'Awesome work on "$sessionTitle"! You focused for $durationMinutes minutes.',
    );
  }

  Future<void> notifyPomodoroPhase({
    required String phaseName,
    required String message,
    bool enabled = true,
  }) async {
    if (!enabled) return;
    await showNotification(
      title: '🍅 Pomodoro: $phaseName',
      body: message,
    );
  }

  Future<void> notifyGoalReached({
    required String goalTitle,
    bool enabled = true,
  }) async {
    if (!enabled) return;
    await showNotification(
      title: '🏆 Goal Achieved!',
      body: 'Congratulations! You reached your $goalTitle.',
    );
  }
}
