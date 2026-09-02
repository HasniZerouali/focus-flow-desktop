import 'package:flutter_test/flutter_test.dart';
import 'package:timer_desktop/core/services/backup_service.dart';
import 'package:timer_desktop/core/storage/models.dart';

void main() {
  group('BackupService', () {
    test('validates valid backup JSON schema successfully', () {
      const validJson = '''
      {
        "app": "FocusFlow",
        "version": 1,
        "exportedAt": "2026-09-02T14:00:00.000Z",
        "categories": [{"id": "1", "name": "Dev", "colorHex": "6366F1", "iconName": "code"}],
        "tasks": [{"id": "t1", "title": "Test", "categoryId": "1", "categoryName": "Dev", "priority": "medium", "estimatedMinutes": 25, "completed": false, "createdAt": "2026-09-02T14:00:00.000Z"}],
        "sessions": [{"id": "s1", "title": "Focus 1", "categoryId": "1", "categoryName": "Dev", "startedAt": "2026-09-02T14:00:00.000Z", "endedAt": "2026-09-02T14:30:00.000Z", "durationSeconds": 1800, "mode": "free", "state": "completed"}],
        "settings": {"themeMode": "dark"}
      }
      ''';

      final result = BackupService.instance.validateBackup(validJson);
      expect(result.isValid, true);
      expect(result.sessionCount, 1);
      expect(result.taskCount, 1);
      expect(result.categoryCount, 1);
    });

    test('rejects corrupted or incomplete JSON', () {
      const malformedJson = '{ broken json ';
      final result1 = BackupService.instance.validateBackup(malformedJson);
      expect(result1.isValid, false);
      expect(result1.error, isNotNull);

      const missingFields = '{"app": "FocusFlow"}';
      final result2 = BackupService.instance.validateBackup(missingFields);
      expect(result2.isValid, false);
    });

    test('exportSessionsToCsv produces valid RFC-4180 CSV with escaped fields', () {
      final session = FocusSessionModel(
        id: 's100',
        title: 'Work on "Critical, Complex" Module',
        categoryId: 'c1',
        categoryName: 'Development',
        startedAt: DateTime(2026, 9, 2, 10, 0),
        endedAt: DateTime(2026, 9, 2, 11, 0),
        durationSeconds: 3600,
        mode: TimerMode.free,
        state: SessionState.completed,
        rating: 5,
        notes: 'Notes with, comma and "quotes"',
      );

      final csv = BackupService.instance.exportSessionsToCsv([session]);

      expect(csv, contains('Id,Title,Category,Task,StartedAt'));
      expect(csv, contains('"Work on ""Critical, Complex"" Module"'));
      expect(csv, contains('"Notes with, comma and ""quotes"""'));
      expect(csv, contains('60,3600')); // 60 mins, 3600 secs
    });
  });
}
