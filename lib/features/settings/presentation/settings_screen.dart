import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/sessions_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/confirm_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.watch(settingsProvider.notifier);
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings & Preferences',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure your workspace aesthetics, Windows integration, and data backups.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 1. APPEARANCE
                _buildSectionHeader('Appearance', PhosphorIconsRegular.palette),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          'Select your preferred application color theme.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildThemeOption(
                              label: 'Dark Mode',
                              value: 'dark',
                              currentValue: settings.themeMode,
                              icon: PhosphorIconsRegular.moon,
                              isDark: isDark,
                              onTap: () => settingsNotifier.setThemeMode('dark'),
                            ),
                            const SizedBox(width: 14),
                            _buildThemeOption(
                              label: 'Light Mode',
                              value: 'light',
                              currentValue: settings.themeMode,
                              icon: PhosphorIconsRegular.sun,
                              isDark: isDark,
                              onTap: () => settingsNotifier.setThemeMode('light'),
                            ),
                            const SizedBox(width: 14),
                            _buildThemeOption(
                              label: 'System Sync',
                              value: 'system',
                              currentValue: settings.themeMode,
                              icon: PhosphorIconsRegular.laptop,
                              isDark: isDark,
                              onTap: () => settingsNotifier.setThemeMode('system'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 2. WINDOWS INTEGRATION & BEHAVIOR
                _buildSectionHeader('Windows Desktop Integration', PhosphorIconsRegular.windowsLogo),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Minimize to System Tray', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Closing the window hides it to the Windows notification tray rather than terminating it.', style: TextStyle(fontSize: 12)),
                          value: settings.minimizeToTray,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            settingsNotifier.updateSettings(settings.copyWith(minimizeToTray: val));
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Launch at Windows Startup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Automatically launch Focus Flow in the background on Windows user login.', style: TextStyle(fontSize: 12)),
                          value: settings.startWithWindows,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            settingsNotifier.updateSettings(settings.copyWith(startWithWindows: val));
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Native Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Show native Windows toast notifications when sessions or Pomodoro breaks finish.', style: TextStyle(fontSize: 12)),
                          value: settings.notificationsEnabled,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            settingsNotifier.updateSettings(settings.copyWith(notificationsEnabled: val));
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Confirm Before Deletion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Require confirmation dialog before deleting tasks or sessions from history.', style: TextStyle(fontSize: 12)),
                          value: settings.confirmBeforeDelete,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            settingsNotifier.updateSettings(settings.copyWith(confirmBeforeDelete: val));
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 3. KEYBOARD SHORTCUTS REFERENCE
                _buildSectionHeader('Keyboard Shortcuts', PhosphorIconsRegular.keyboard),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildShortcutRow('Start / Pause Active Focus', AppConstants.shortcutStartPause, isDark),
                        const Divider(),
                        _buildShortcutRow('Finish Focus Session', AppConstants.shortcutFinish, isDark),
                        const Divider(),
                        _buildShortcutRow('Navigate to Pomodoro', AppConstants.shortcutPomodoro, isDark),
                        const Divider(),
                        _buildShortcutRow('Navigate to Tasks', AppConstants.shortcutTasks, isDark),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 4. DATA MANAGEMENT, BACKUP & EXPORT
                _buildSectionHeader('Data & Backups', PhosphorIconsRegular.database),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Backup & Migration', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          'Export your entire database into a single validated JSON file, or restore from a previous backup.',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _handleExportJson(context, db),
                              icon: const Icon(PhosphorIconsRegular.export, size: 16),
                              label: const Text('Export JSON Backup'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _handleImportJson(context, ref, db),
                              icon: const Icon(PhosphorIconsRegular.fileArrowUp, size: 16),
                              label: const Text('Import JSON Backup'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _handleExportCsv(context, db),
                              icon: const Icon(PhosphorIconsRegular.fileCsv, size: 16),
                              label: const Text('Export CSV Sessions'),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                              onPressed: () => _handleClearAllData(context, ref, db),
                              icon: const Icon(PhosphorIconsRegular.trash, size: 16),
                              label: const Text('Clear All Data'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // 5. PRIVACY & LOCAL OFFLINE NOTICE
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(PhosphorIconsRegular.shieldCheck, size: 24, color: AppColors.success),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '100% Offline & Private by Design',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Focus Flow has no account creation, no analytics, and makes zero network requests. All your session history, tasks, categories, and metrics are stored strictly on this Windows machine in a native SQLite database.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildThemeOption({
    required String label,
    required String value,
    required String currentValue,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = value == currentValue;
    final unselectedColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder);

    return Expanded(
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                : (isDark ? Colors.transparent : AppColors.lightSurfaceCard),
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: isSelected ? AppColors.primary : unselectedColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutRow(String action, String shortcut, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportJson(BuildContext context, dynamic db) async {
    final jsonStr = await BackupService.instance.exportBackupJson(db);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your database export is ready. Copy it to your clipboard to save safely:'),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(
                  color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup copied to clipboard!')),
              );
            },
            icon: const Icon(PhosphorIconsRegular.copy, size: 16),
            label: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImportJson(BuildContext context, WidgetRef ref, dynamic db) async {
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste your exported Focus Flow JSON backup string below:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Paste JSON content here...',
              ),
              maxLines: 6,
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final raw = textController.text.trim();
              final validation = BackupService.instance.validateBackup(raw);

              if (!validation.isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import Failed: ${validation.error}')),
                );
                return;
              }

              final success = await BackupService.instance.importBackupJson(db, raw);
              if (success) {
                ref.invalidate(sessionsProvider);
                ref.invalidate(tasksProvider);
                ref.invalidate(settingsProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully imported ${validation.sessionCount} sessions & ${validation.taskCount} tasks!')),
                  );
                }
              }
            },
            child: const Text('Validate & Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportCsv(BuildContext context, dynamic db) async {
    final sessions = await db.getAllSessions();
    final csvStr = BackupService.instance.exportSessionsToCsv(sessions);
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export CSV Sessions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Generated standard RFC-4180 CSV with ${sessions.length} sessions:'),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(
                  color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvStr,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvStr));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard!')));
            },
            icon: const Icon(PhosphorIconsRegular.copy, size: 16),
            label: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClearAllData(BuildContext context, WidgetRef ref, dynamic db) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Reset All Data',
      message: 'This will permanently wipe all focus sessions, tasks, and historical metrics from local SQLite. This action cannot be undone.',
      confirmLabel: 'Wipe Everything',
      isDestructive: true,
    );

    if (confirmed) {
      await db.clearAllData();
      ref.invalidate(sessionsProvider);
      ref.invalidate(tasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been cleared.')),
        );
      }
    }
  }
}
