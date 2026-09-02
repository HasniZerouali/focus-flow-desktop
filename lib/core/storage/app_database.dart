import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'dart:convert';
import 'models.dart';
import '../constants/app_constants.dart';

part 'app_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get colorHex => text()();
  TextColumn get iconName => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text()();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(25))();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get totalFocusTimeSeconds => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class FocusSessions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get categoryId => text()();
  TextColumn get taskId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  IntColumn get targetDurationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get mode => text()(); // free, countdown, pomodoro
  TextColumn get state => text()(); // completed, cancelled
  IntColumn get rating => integer().nullable()(); // 1 to 5
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get pauseCount => integer().withDefault(const Constant(0))();
  IntColumn get distractionCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Distractions extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get type => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class DailyGoals extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()(); // YYYY-MM-DD
  IntColumn get targetFocusMinutes => integer()();
  IntColumn get targetTasksCount => integer()();
  IntColumn get completedFocusMinutes => integer().withDefault(const Constant(0))();
  IntColumn get completedTasksCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class KeyValueEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Categories, Tasks, FocusSessions, Distractions, DailyGoals, KeyValueEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'focus_flow_desktop_db');
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Seed default categories
        for (final cat in AppConstants.defaultCategories) {
          await into(categories).insert(
            CategoriesCompanion.insert(
              id: cat['name'] as String,
              name: cat['name'] as String,
              colorHex: cat['color'] as String,
              iconName: cat['icon'] as String,
              isCustom: const Value(false),
              isArchived: const Value(false),
            ),
          );
        }
      },
    );
  }

  // --- Category Methods ---
  Future<List<CategoryModel>> getAllCategories() async {
    final rows = await (select(categories)
          ..where((tbl) => tbl.isArchived.equals(false))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.name)]))
        .get();

    return rows
        .map((r) => CategoryModel(
              id: r.id,
              name: r.name,
              colorHex: r.colorHex,
              iconName: r.iconName,
              isCustom: r.isCustom,
              isArchived: r.isArchived,
            ))
        .toList();
  }

  Future<void> insertCategory(CategoryModel cat) async {
    await into(categories).insert(
      CategoriesCompanion.insert(
        id: cat.id,
        name: cat.name,
        colorHex: cat.colorHex,
        iconName: cat.iconName,
        isCustom: Value(cat.isCustom),
        isArchived: Value(cat.isArchived),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  // --- Task Methods ---
  Future<List<TaskModel>> getAllTasks() async {
    final taskRows = await (select(tasks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    final catRows = await select(categories).get();
    final catMap = {for (var c in catRows) c.id: c.name};

    return taskRows
        .map((t) => TaskModel(
              id: t.id,
              title: t.title,
              description: t.description,
              categoryId: t.categoryId,
              categoryName: catMap[t.categoryId] ?? 'General',
              priority: TaskPriority.values.byName(t.priority),
              estimatedMinutes: t.estimatedMinutes,
              completed: t.completed,
              createdAt: t.createdAt,
              completedAt: t.completedAt,
              totalFocusTimeSeconds: t.totalFocusTimeSeconds,
            ))
        .toList();
  }

  Future<void> upsertTask(TaskModel task) async {
    await into(tasks).insert(
      TasksCompanion.insert(
        id: task.id,
        title: task.title,
        description: Value(task.description),
        categoryId: task.categoryId,
        priority: Value(task.priority.name),
        estimatedMinutes: Value(task.estimatedMinutes),
        completed: Value(task.completed),
        createdAt: task.createdAt,
        completedAt: Value(task.completedAt),
        totalFocusTimeSeconds: Value(task.totalFocusTimeSeconds),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteTask(String id) async {
    await (delete(tasks)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> addFocusTimeToTask(String taskId, int additionalSeconds) async {
    final existing = await (select(tasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (existing != null) {
      await (update(tasks)..where((t) => t.id.equals(taskId))).write(
        TasksCompanion(
          totalFocusTimeSeconds: Value(existing.totalFocusTimeSeconds + additionalSeconds),
        ),
      );
    }
  }

  // --- Focus Session Methods ---
  Future<List<FocusSessionModel>> getAllSessions() async {
    final sessionRows = await (select(focusSessions)..orderBy([(s) => OrderingTerm.desc(s.startedAt)])).get();
    final catRows = await select(categories).get();
    final taskRows = await select(tasks).get();

    final catMap = {for (var c in catRows) c.id: c.name};
    final taskMap = {for (var t in taskRows) t.id: t.title};

    return sessionRows
        .map((s) => FocusSessionModel(
              id: s.id,
              title: s.title,
              categoryId: s.categoryId,
              categoryName: catMap[s.categoryId] ?? 'General',
              taskId: s.taskId,
              taskTitle: s.taskId != null ? taskMap[s.taskId] : null,
              startedAt: s.startedAt,
              endedAt: s.endedAt,
              durationSeconds: s.durationSeconds,
              targetDurationSeconds: s.targetDurationSeconds,
              mode: TimerMode.values.byName(s.mode),
              state: SessionState.values.byName(s.state),
              rating: s.rating,
              notes: s.notes,
              pauseCount: s.pauseCount,
              distractionCount: s.distractionCount,
            ))
        .toList();
  }

  Future<void> insertSession(FocusSessionModel session) async {
    await into(focusSessions).insert(
      FocusSessionsCompanion.insert(
        id: session.id,
        title: session.title,
        categoryId: session.categoryId,
        taskId: Value(session.taskId),
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        durationSeconds: session.durationSeconds,
        targetDurationSeconds: Value(session.targetDurationSeconds),
        mode: session.mode.name,
        state: session.state.name,
        rating: Value(session.rating),
        notes: Value(session.notes),
        pauseCount: Value(session.pauseCount),
        distractionCount: Value(session.distractionCount),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> updateSession(FocusSessionModel session) async {
    await (update(focusSessions)..where((s) => s.id.equals(session.id))).write(
      FocusSessionsCompanion(
        title: Value(session.title),
        categoryId: Value(session.categoryId),
        rating: Value(session.rating),
        notes: Value(session.notes),
      ),
    );
  }

  Future<void> deleteSession(String id) async {
    await (delete(focusSessions)..where((s) => s.id.equals(id))).go();
    await (delete(distractions)..where((d) => d.sessionId.equals(id))).go();
  }

  // --- Distraction Methods ---
  Future<void> insertDistraction(DistractionModel distraction) async {
    await into(distractions).insert(
      DistractionsCompanion.insert(
        id: distraction.id,
        sessionId: distraction.sessionId,
        type: distraction.type,
        timestamp: distraction.timestamp,
        note: Value(distraction.note),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<List<DistractionModel>> getDistractionsForSession(String sessionId) async {
    final rows = await (select(distractions)
          ..where((d) => d.sessionId.equals(sessionId))
          ..orderBy([(d) => OrderingTerm.asc(d.timestamp)]))
        .get();

    return rows
        .map((d) => DistractionModel(
              id: d.id,
              sessionId: d.sessionId,
              type: d.type,
              timestamp: d.timestamp,
              note: d.note,
            ))
        .toList();
  }

  // --- Active Session Recovery (survives restart & sleep) ---
  Future<void> saveActiveSession(ActiveSessionRecovery session) async {
    final jsonStr = jsonEncode(session.toJson());
    await into(keyValueEntries).insert(
      KeyValueEntriesCompanion.insert(
        key: 'active_session',
        value: jsonStr,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<ActiveSessionRecovery?> getActiveSession() async {
    final entry = await (select(keyValueEntries)..where((k) => k.key.equals('active_session'))).getSingleOrNull();
    if (entry == null || entry.value.isEmpty) return null;
    try {
      final map = jsonDecode(entry.value) as Map<String, dynamic>;
      return ActiveSessionRecovery.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    await (delete(keyValueEntries)..where((k) => k.key.equals('active_session'))).go();
  }

  // --- User Settings Persistence ---
  Future<void> saveUserSettings(UserSettingsModel settings) async {
    final jsonStr = jsonEncode(settings.toJson());
    await into(keyValueEntries).insert(
      KeyValueEntriesCompanion.insert(
        key: 'user_settings',
        value: jsonStr,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<UserSettingsModel> getUserSettings() async {
    final entry = await (select(keyValueEntries)..where((k) => k.key.equals('user_settings'))).getSingleOrNull();
    if (entry == null || entry.value.isEmpty) return const UserSettingsModel();
    try {
      final map = jsonDecode(entry.value) as Map<String, dynamic>;
      return UserSettingsModel.fromJson(map);
    } catch (_) {
      return const UserSettingsModel();
    }
  }

  // --- Daily Goal Methods ---
  Future<DailyGoalModel?> getDailyGoal(String dateIso) async {
    final row = await (select(dailyGoals)..where((g) => g.date.equals(dateIso))).getSingleOrNull();
    if (row == null) return null;
    return DailyGoalModel(
      id: row.id,
      date: row.date,
      targetFocusMinutes: row.targetFocusMinutes,
      targetTasksCount: row.targetTasksCount,
      completedFocusMinutes: row.completedFocusMinutes,
      completedTasksCount: row.completedTasksCount,
    );
  }

  Future<void> saveDailyGoal(DailyGoalModel goal) async {
    await into(dailyGoals).insert(
      DailyGoalsCompanion.insert(
        id: goal.id,
        date: goal.date,
        targetFocusMinutes: goal.targetFocusMinutes,
        targetTasksCount: goal.targetTasksCount,
        completedFocusMinutes: Value(goal.completedFocusMinutes),
        completedTasksCount: Value(goal.completedTasksCount),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  // --- Clear All Data ---
  Future<void> clearAllData() async {
    await delete(focusSessions).go();
    await delete(distractions).go();
    await delete(tasks).go();
    await delete(dailyGoals).go();
    await clearActiveSession();
  }
}
