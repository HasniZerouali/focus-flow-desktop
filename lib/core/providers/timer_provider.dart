import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/focus_timer_service.dart';
import 'database_provider.dart';

final timerServiceProvider = ChangeNotifierProvider<FocusTimerService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = FocusTimerService(db);
  // Restore active session asynchronously on launch
  service.restoreIfActive();
  return service;
});

final timerSnapshotProvider = Provider<TimerSnapshot>((ref) {
  final service = ref.watch(timerServiceProvider);
  return service.snapshot;
});
