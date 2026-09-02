import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/app_database.dart';
import '../storage/models.dart';
import 'database_provider.dart';

class TasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final AppDatabase _db;

  TasksNotifier(this._db) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      state = const AsyncValue.loading();
      final tasks = await _db.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveTask(TaskModel task) async {
    try {
      await _db.upsertTask(task);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleTaskCompleted(String id) async {
    final currentTasks = state.valueOrNull ?? [];
    final task = currentTasks.firstWhere((t) => t.id == id, orElse: () => throw Exception('Task not found'));
    final isNowCompleted = !task.completed;
    final updated = task.copyWith(
      completed: isNowCompleted,
      completedAt: isNowCompleted ? DateTime.now() : null,
    );
    await saveTask(updated);
  }

  Future<void> deleteTask(String id) async {
    try {
      await _db.deleteTask(id);
      await loadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskModel>>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TasksNotifier(db);
});
