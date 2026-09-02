import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../constants/app_constants.dart';

class WindowService with WindowListener {
  WindowService._();
  static final WindowService instance = WindowService._();

  bool minimizeToTray = true;

  Future<void> initialize({required bool minimizeToTray}) async {
    this.minimizeToTray = minimizeToTray;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await windowManager.ensureInitialized();
        windowManager.addListener(this);

        const windowOptions = WindowOptions(
          size: Size(AppConstants.defaultWindowWidth, AppConstants.defaultWindowHeight),
          minimumSize: Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden, // Enables custom titlebar
          title: AppConstants.appName,
        );

        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
          await windowManager.setPreventClose(true);
        });
      } catch (e) {
        debugPrint('Window manager initialization failed: $e');
      }
    }
  }

  void updateMinimizeToTray(bool value) {
    minimizeToTray = value;
  }

  @override
  void onWindowClose() async {
    if (minimizeToTray) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  Future<void> minimize() async => windowManager.minimize();
  Future<void> maximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
  Future<void> close() async {
    if (minimizeToTray) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }

  void dispose() {
    windowManager.removeListener(this);
  }
}
