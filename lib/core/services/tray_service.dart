import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService with TrayListener {
  TrayService._();
  static final TrayService instance = TrayService._();

  VoidCallback? onOpenApp;
  VoidCallback? onTogglePause;
  VoidCallback? onStartFocus;

  bool _initialized = false;
  bool _isFocusRunning = false;

  Future<void> initialize({
    VoidCallback? onOpenApp,
    VoidCallback? onTogglePause,
    VoidCallback? onStartFocus,
  }) async {
    this.onOpenApp = onOpenApp;
    this.onTogglePause = onTogglePause;
    this.onStartFocus = onStartFocus;

    if (_initialized) return;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        trayManager.addListener(this);
        // Using tray_icon.png from assets
        await trayManager.setIcon('assets/icons/tray_icon.png');
        await updateTrayMenu();
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to initialize tray_manager: $e');
      }
    }
  }

  void updateFocusState({required bool isRunning}) {
    _isFocusRunning = isRunning;
    updateTrayMenu();
  }

  Future<void> updateTrayMenu() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        final menu = Menu(
          items: [
            MenuItem(
              key: 'open_app',
              label: 'Open Focus Flow',
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'toggle_focus',
              label: _isFocusRunning ? 'Pause Focus' : 'Resume Focus',
            ),
            MenuItem(
              key: 'start_focus',
              label: 'Start New Session',
            ),
            MenuItem.separator(),
            MenuItem(
              key: 'quit_app',
              label: 'Exit Focus Flow',
            ),
          ],
        );
        await trayManager.setContextMenu(menu);
      } catch (e) {
        debugPrint('Failed to update tray menu: $e');
      }
    }
  }

  @override
  void onTrayIconMouseDown() {
    openWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open_app':
        openWindow();
        break;
      case 'toggle_focus':
        onTogglePause?.call();
        break;
      case 'start_focus':
        openWindow();
        onStartFocus?.call();
        break;
      case 'quit_app':
        exitApp();
        break;
    }
  }

  Future<void> openWindow() async {
    try {
      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }
      await windowManager.show();
      await windowManager.focus();
      onOpenApp?.call();
    } catch (e) {
      debugPrint('Error restoring window: $e');
    }
  }

  Future<void> exitApp() async {
    try {
      await windowManager.destroy();
    } catch (e) {
      exit(0);
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
