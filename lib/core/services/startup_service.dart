import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

class StartupService {
  StartupService._();
  static final StartupService instance = StartupService._();

  bool _initialized = false;
  File? _macPlistFile;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return;

    if (Platform.isWindows || Platform.isLinux) {
      try {
        launchAtStartup.setup(
          appName: 'FocusFlow',
          appPath: Platform.resolvedExecutable,
        );
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to setup launch_at_startup: $e');
      }
    } else if (Platform.isMacOS) {
      try {
        final home = Platform.environment['HOME'];
        if (home != null) {
          _macPlistFile = File('$home/Library/LaunchAgents/com.focusflow.desktop.plist');
        }
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to initialize macOS startup service: $e');
      }
    }
  }

  Future<bool> isEnabled() async {
    if (!_initialized) return false;
    if (Platform.isWindows || Platform.isLinux) {
      try {
        return await launchAtStartup.isEnabled();
      } catch (_) {
        return false;
      }
    } else if (Platform.isMacOS && _macPlistFile != null) {
      return _macPlistFile!.existsSync();
    }
    return false;
  }

  Future<void> setLaunchAtStartup(bool enable) async {
    if (!_initialized) return;
    try {
      if (Platform.isWindows || Platform.isLinux) {
        if (enable) {
          await launchAtStartup.enable();
        } else {
          await launchAtStartup.disable();
        }
      } else if (Platform.isMacOS && _macPlistFile != null) {
        if (enable) {
          final parentDir = _macPlistFile!.parent;
          if (!parentDir.existsSync()) {
            await parentDir.create(recursive: true);
          }
          final executable = Platform.resolvedExecutable;
          final content = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.focusflow.desktop</string>
    <key>ProgramArguments</key>
    <array>
        <string>$executable</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
''';
          await _macPlistFile!.writeAsString(content);
        } else {
          if (_macPlistFile!.existsSync()) {
            await _macPlistFile!.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error toggling launch at startup: $e');
    }
  }
}
