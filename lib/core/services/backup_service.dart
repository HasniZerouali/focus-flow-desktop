import 'dart:convert';
import '../storage/app_database.dart';
import '../storage/models.dart';

class BackupValidationResult {
  final bool isValid;
  final String? error;
  final int sessionCount;
  final int taskCount;
  final int categoryCount;

  const BackupValidationResult({
    required this.isValid,
    this.error,
    this.sessionCount = 0,
    this.taskCount = 0,
    this.categoryCount = 0,
  });
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  /// Exports all data to a structured JSON string.
  Future<String> exportBackupJson(AppDatabase db) async {
    final sessions = await db.getAllSessions();
    final tasks = await db.getAllTasks();
    final categories = await db.getAllCategories();
    final settings = await db.getUserSettings();

    final exportData = {
      'app': 'FocusFlow',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'settings': settings.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Validates a backup JSON string before import.
  BackupValidationResult validateBackup(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      if (data is! Map<String, dynamic>) {
        return const BackupValidationResult(isValid: false, error: 'File does not contain a valid JSON object.');
      }

      if (!data.containsKey('sessions') || !data.containsKey('tasks')) {
        return const BackupValidationResult(isValid: false, error: 'Backup is missing core "sessions" or "tasks" records.');
      }

      final sessions = data['sessions'] as List?;
      final tasks = data['tasks'] as List?;
      final categories = data['categories'] as List?;

      return BackupValidationResult(
        isValid: true,
        sessionCount: sessions?.length ?? 0,
        taskCount: tasks?.length ?? 0,
        categoryCount: categories?.length ?? 0,
      );
    } catch (e) {
      return BackupValidationResult(isValid: false, error: 'Invalid JSON format: $e');
    }
  }

  /// Imports validated JSON backup data into SQLite.
  Future<bool> importBackupJson(AppDatabase db, String jsonString) async {
    final validation = validateBackup(jsonString);
    if (!validation.isValid) return false;

    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    await db.transaction(() async {
      // Import categories
      if (data.containsKey('categories')) {
        final categoriesList = (data['categories'] as List).cast<Map<String, dynamic>>();
        for (final catJson in categoriesList) {
          try {
            await db.insertCategory(CategoryModel.fromJson(catJson));
          } catch (_) {}
        }
      }

      // Import tasks
      if (data.containsKey('tasks')) {
        final tasksList = (data['tasks'] as List).cast<Map<String, dynamic>>();
        for (final taskJson in tasksList) {
          try {
            await db.upsertTask(TaskModel.fromJson(taskJson));
          } catch (_) {}
        }
      }

      // Import sessions
      if (data.containsKey('sessions')) {
        final sessionsList = (data['sessions'] as List).cast<Map<String, dynamic>>();
        for (final sessionJson in sessionsList) {
          try {
            await db.insertSession(FocusSessionModel.fromJson(sessionJson));
          } catch (_) {}
        }
      }

      // Import settings
      if (data.containsKey('settings')) {
        try {
          final settings = UserSettingsModel.fromJson(data['settings'] as Map<String, dynamic>);
          await db.saveUserSettings(settings);
        } catch (_) {}
      }
    });

    return true;
  }

  /// Generates CSV format for sessions export.
  String exportSessionsToCsv(List<FocusSessionModel> sessions) {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('Id,Title,Category,Task,StartedAt,EndedAt,DurationMinutes,DurationSeconds,Mode,State,Rating,Notes,PauseCount,DistractionCount');

    for (final s in sessions) {
      final durationMins = (s.durationSeconds / 60).round();
      final escapedTitle = _escapeCsv(s.title);
      final escapedCategory = _escapeCsv(s.categoryName);
      final escapedTask = _escapeCsv(s.taskTitle ?? '');
      final escapedNotes = _escapeCsv(s.notes);

      buffer.writeln(
        '${s.id},$escapedTitle,$escapedCategory,$escapedTask,${s.startedAt.toIso8601String()},${s.endedAt.toIso8601String()},'
        '$durationMins,${s.durationSeconds},${s.mode.name},${s.state.name},${s.rating ?? ""},$escapedNotes,${s.pauseCount},${s.distractionCount}',
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
