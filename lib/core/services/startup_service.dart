import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

class StartupService {
  StartupService._();
  static final StartupService instance = StartupService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!kIsWeb && Platform.isWindows) {
      try {
        launchAtStartup.setup(
          appName: 'FocusFlow',
          appPath: Platform.resolvedExecutable,
        );
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to setup launch_at_startup: $e');
      }
    }
  }

  Future<bool> isEnabled() async {
    if (!_initialized) return false;
    try {
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<void> setLaunchAtStartup(bool enable) async {
    if (!_initialized) return;
    try {
      if (enable) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (e) {
      debugPrint('Error toggling launch at startup: $e');
    }
  }
}
