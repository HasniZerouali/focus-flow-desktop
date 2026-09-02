import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_database.dart';
import '../storage/models.dart';
import 'database_provider.dart';

class SessionsNotifier extends StateNotifier<AsyncValue<List<FocusSessionModel>>> {
  final AppDatabase _db;

  SessionsNotifier(this._db) : super(const AsyncValue.loading()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    try {
      state = const AsyncValue.loading();
      final sessions = await _db.getAllSessions();
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await _db.deleteSession(id);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSession(FocusSessionModel session) async {
    try {
      await _db.updateSession(session);
      await loadSessions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final sessionsProvider = StateNotifierProvider<SessionsNotifier, AsyncValue<List<FocusSessionModel>>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SessionsNotifier(db);
});
