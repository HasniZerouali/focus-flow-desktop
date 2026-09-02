import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/startup_service.dart';
import '../services/window_service.dart';
import '../storage/app_database.dart';
import '../storage/models.dart';
import 'database_provider.dart';

class SettingsNotifier extends StateNotifier<UserSettingsModel> {
  final AppDatabase _db;

  SettingsNotifier(this._db) : super(const UserSettingsModel()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final settings = await _db.getUserSettings();
    state = settings;
    WindowService.instance.updateMinimizeToTray(settings.minimizeToTray);
  }

  Future<void> updateSettings(UserSettingsModel newSettings) async {
    state = newSettings;
    await _db.saveUserSettings(newSettings);
    WindowService.instance.updateMinimizeToTray(newSettings.minimizeToTray);
    await StartupService.instance.setLaunchAtStartup(newSettings.startWithWindows);
  }

  Future<void> setThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    await updateSettings(updated);
  }

  ThemeMode get flutterThemeMode {
    switch (state.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettingsModel>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SettingsNotifier(db);
});
