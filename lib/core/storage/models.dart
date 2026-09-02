import '../constants/app_constants.dart';
import '../../features/focus/domain/session_state.dart';
import '../../features/focus/domain/timer_mode.dart';
import '../../features/tasks/domain/task_priority.dart';

export '../../features/focus/domain/session_state.dart';
export '../../features/focus/domain/timer_mode.dart';
export '../../features/tasks/domain/task_priority.dart';

class CategoryModel {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;
  final bool isCustom;
  final bool isArchived;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
    this.isCustom = false,
    this.isArchived = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
    bool? isCustom,
    bool? isArchived,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isCustom: isCustom ?? this.isCustom,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'iconName': iconName,
        'isCustom': isCustom,
        'isArchived': isArchived,
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String,
        iconName: json['iconName'] as String,
        isCustom: json['isCustom'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
      );
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final TaskPriority priority;
  final int estimatedMinutes;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int totalFocusTimeSeconds;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.categoryId,
    required this.categoryName,
    this.priority = TaskPriority.medium,
    this.estimatedMinutes = 25,
    this.completed = false,
    required this.createdAt,
    this.completedAt,
    this.totalFocusTimeSeconds = 0,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? categoryName,
    TaskPriority? priority,
    int? estimatedMinutes,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    int? totalFocusTimeSeconds,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      totalFocusTimeSeconds: totalFocusTimeSeconds ?? this.totalFocusTimeSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'priority': priority.name,
        'estimatedMinutes': estimatedMinutes,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'totalFocusTimeSeconds': totalFocusTimeSeconds,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String? ?? 'General',
        priority: TaskPriority.values.byName(json['priority'] as String? ?? 'medium'),
        estimatedMinutes: json['estimatedMinutes'] as int? ?? 25,
        completed: json['completed'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        totalFocusTimeSeconds: json['totalFocusTimeSeconds'] as int? ?? 0,
      );
}

class FocusSessionModel {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String? taskId;
  final String? taskTitle;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final int targetDurationSeconds;
  final TimerMode mode;
  final SessionState state;
  final int? rating; // 1 to 5
  final String notes;
  final int pauseCount;
  final int distractionCount;

  const FocusSessionModel({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    this.taskId,
    this.taskTitle,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    this.targetDurationSeconds = 0,
    required this.mode,
    required this.state,
    this.rating,
    this.notes = '',
    this.pauseCount = 0,
    this.distractionCount = 0,
  });

  FocusSessionModel copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? categoryName,
    String? taskId,
    String? taskTitle,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    int? targetDurationSeconds,
    TimerMode? mode,
    SessionState? state,
    int? rating,
    String? notes,
    int? pauseCount,
    int? distractionCount,
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      targetDurationSeconds: targetDurationSeconds ?? this.targetDurationSeconds,
      mode: mode ?? this.mode,
      state: state ?? this.state,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      pauseCount: pauseCount ?? this.pauseCount,
      distractionCount: distractionCount ?? this.distractionCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'targetDurationSeconds': targetDurationSeconds,
        'mode': mode.name,
        'state': state.name,
        'rating': rating,
        'notes': notes,
        'pauseCount': pauseCount,
        'distractionCount': distractionCount,
      };

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) => FocusSessionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String? ?? 'General',
        taskId: json['taskId'] as String?,
        taskTitle: json['taskTitle'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: DateTime.parse(json['endedAt'] as String),
        durationSeconds: json['durationSeconds'] as int,
        targetDurationSeconds: json['targetDurationSeconds'] as int? ?? 0,
        mode: TimerMode.values.byName(json['mode'] as String? ?? 'free'),
        state: SessionState.values.byName(json['state'] as String? ?? 'completed'),
        rating: json['rating'] as int?,
        notes: json['notes'] as String? ?? '',
        pauseCount: json['pauseCount'] as int? ?? 0,
        distractionCount: json['distractionCount'] as int? ?? 0,
      );
}

class DistractionModel {
  final String id;
  final String sessionId;
  final String type;
  final DateTime timestamp;
  final String note;

  const DistractionModel({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.timestamp,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory DistractionModel.fromJson(Map<String, dynamic> json) => DistractionModel(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        type: json['type'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        note: json['note'] as String? ?? '',
      );
}

class DailyGoalModel {
  final String id;
  final String date; // YYYY-MM-DD
  final int targetFocusMinutes;
  final int targetTasksCount;
  final int completedFocusMinutes;
  final int completedTasksCount;

  const DailyGoalModel({
    required this.id,
    required this.date,
    required this.targetFocusMinutes,
    required this.targetTasksCount,
    this.completedFocusMinutes = 0,
    this.completedTasksCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'targetFocusMinutes': targetFocusMinutes,
        'targetTasksCount': targetTasksCount,
        'completedFocusMinutes': completedFocusMinutes,
        'completedTasksCount': completedTasksCount,
      };

  factory DailyGoalModel.fromJson(Map<String, dynamic> json) => DailyGoalModel(
        id: json['id'] as String,
        date: json['date'] as String,
        targetFocusMinutes: json['targetFocusMinutes'] as int,
        targetTasksCount: json['targetTasksCount'] as int,
        completedFocusMinutes: json['completedFocusMinutes'] as int? ?? 0,
        completedTasksCount: json['completedTasksCount'] as int? ?? 0,
      );
}

class UserSettingsModel {
  final String themeMode; // 'system', 'light', 'dark'
  final bool soundEnabled;
  final bool notificationsEnabled;
  final int defaultFocusMinutes;
  final int defaultShortBreakMinutes;
  final int defaultLongBreakMinutes;
  final int pomodoroCycles;
  final int dailyFocusGoalMinutes;
  final int weeklyFocusGoalMinutes;
  final int dailyTaskGoal;
  final int streakMinMinutes;
  final bool startWithWindows;
  final bool minimizeToTray;
  final bool confirmBeforeDelete;

  const UserSettingsModel({
    this.themeMode = 'dark',
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.defaultFocusMinutes = AppConstants.defaultCountdownMinutes,
    this.defaultShortBreakMinutes = AppConstants.defaultShortBreakMinutes,
    this.defaultLongBreakMinutes = AppConstants.defaultLongBreakMinutes,
    this.pomodoroCycles = AppConstants.defaultPomodoroCycles,
    this.dailyFocusGoalMinutes = AppConstants.defaultDailyFocusMinutes,
    this.weeklyFocusGoalMinutes = AppConstants.defaultWeeklyFocusMinutes,
    this.dailyTaskGoal = AppConstants.defaultDailyTaskGoal,
    this.streakMinMinutes = AppConstants.defaultStreakMinMinutes,
    this.startWithWindows = false,
    this.minimizeToTray = true,
    this.confirmBeforeDelete = true,
  });

  UserSettingsModel copyWith({
    String? themeMode,
    bool? soundEnabled,
    bool? notificationsEnabled,
    int? defaultFocusMinutes,
    int? defaultShortBreakMinutes,
    int? defaultLongBreakMinutes,
    int? pomodoroCycles,
    int? dailyFocusGoalMinutes,
    int? weeklyFocusGoalMinutes,
    int? dailyTaskGoal,
    int? streakMinMinutes,
    bool? startWithWindows,
    bool? minimizeToTray,
    bool? confirmBeforeDelete,
  }) {
    return UserSettingsModel(
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultFocusMinutes: defaultFocusMinutes ?? this.defaultFocusMinutes,
      defaultShortBreakMinutes: defaultShortBreakMinutes ?? this.defaultShortBreakMinutes,
      defaultLongBreakMinutes: defaultLongBreakMinutes ?? this.defaultLongBreakMinutes,
      pomodoroCycles: pomodoroCycles ?? this.pomodoroCycles,
      dailyFocusGoalMinutes: dailyFocusGoalMinutes ?? this.dailyFocusGoalMinutes,
      weeklyFocusGoalMinutes: weeklyFocusGoalMinutes ?? this.weeklyFocusGoalMinutes,
      dailyTaskGoal: dailyTaskGoal ?? this.dailyTaskGoal,
      streakMinMinutes: streakMinMinutes ?? this.streakMinMinutes,
      startWithWindows: startWithWindows ?? this.startWithWindows,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      confirmBeforeDelete: confirmBeforeDelete ?? this.confirmBeforeDelete,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'soundEnabled': soundEnabled,
        'notificationsEnabled': notificationsEnabled,
        'defaultFocusMinutes': defaultFocusMinutes,
        'defaultShortBreakMinutes': defaultShortBreakMinutes,
        'defaultLongBreakMinutes': defaultLongBreakMinutes,
        'pomodoroCycles': pomodoroCycles,
        'dailyFocusGoalMinutes': dailyFocusGoalMinutes,
        'weeklyFocusGoalMinutes': weeklyFocusGoalMinutes,
        'dailyTaskGoal': dailyTaskGoal,
        'streakMinMinutes': streakMinMinutes,
        'startWithWindows': startWithWindows,
        'minimizeToTray': minimizeToTray,
        'confirmBeforeDelete': confirmBeforeDelete,
      };

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) => UserSettingsModel(
        themeMode: json['themeMode'] as String? ?? 'dark',
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        defaultFocusMinutes: json['defaultFocusMinutes'] as int? ?? AppConstants.defaultCountdownMinutes,
        defaultShortBreakMinutes: json['defaultShortBreakMinutes'] as int? ?? AppConstants.defaultShortBreakMinutes,
        defaultLongBreakMinutes: json['defaultLongBreakMinutes'] as int? ?? AppConstants.defaultLongBreakMinutes,
        pomodoroCycles: json['pomodoroCycles'] as int? ?? AppConstants.defaultPomodoroCycles,
        dailyFocusGoalMinutes: json['dailyFocusGoalMinutes'] as int? ?? AppConstants.defaultDailyFocusMinutes,
        weeklyFocusGoalMinutes: json['weeklyFocusGoalMinutes'] as int? ?? AppConstants.defaultWeeklyFocusMinutes,
        dailyTaskGoal: json['dailyTaskGoal'] as int? ?? AppConstants.defaultDailyTaskGoal,
        streakMinMinutes: json['streakMinMinutes'] as int? ?? AppConstants.defaultStreakMinMinutes,
        startWithWindows: json['startWithWindows'] as bool? ?? false,
        minimizeToTray: json['minimizeToTray'] as bool? ?? true,
        confirmBeforeDelete: json['confirmBeforeDelete'] as bool? ?? true,
      );
}

class ActiveSessionRecovery {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String? taskId;
  final String? taskTitle;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final int accumulatedSeconds;
  final int targetDurationSeconds;
  final TimerMode mode;
  final SessionState state;
  final String notes;
  final int pauseCount;
  final int distractionCount;
  // Pomodoro fields
  final int pomodoroCycle;
  final String pomodoroPhase;

  const ActiveSessionRecovery({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    this.taskId,
    this.taskTitle,
    required this.startedAt,
    this.pausedAt,
    required this.accumulatedSeconds,
    required this.targetDurationSeconds,
    required this.mode,
    required this.state,
    this.notes = '',
    this.pauseCount = 0,
    this.distractionCount = 0,
    this.pomodoroCycle = 1,
    this.pomodoroPhase = 'work',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'startedAt': startedAt.toIso8601String(),
        'pausedAt': pausedAt?.toIso8601String(),
        'accumulatedSeconds': accumulatedSeconds,
        'targetDurationSeconds': targetDurationSeconds,
        'mode': mode.name,
        'state': state.name,
        'notes': notes,
        'pauseCount': pauseCount,
        'distractionCount': distractionCount,
        'pomodoroCycle': pomodoroCycle,
        'pomodoroPhase': pomodoroPhase,
      };

  factory ActiveSessionRecovery.fromJson(Map<String, dynamic> json) => ActiveSessionRecovery(
        id: json['id'] as String,
        title: json['title'] as String,
        categoryId: json['categoryId'] as String,
        categoryName: json['categoryName'] as String? ?? 'General',
        taskId: json['taskId'] as String?,
        taskTitle: json['taskTitle'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String),
        pausedAt: json['pausedAt'] != null ? DateTime.parse(json['pausedAt'] as String) : null,
        accumulatedSeconds: json['accumulatedSeconds'] as int? ?? 0,
        targetDurationSeconds: json['targetDurationSeconds'] as int? ?? 0,
        mode: TimerMode.values.byName(json['mode'] as String? ?? 'free'),
        state: SessionState.values.byName(json['state'] as String? ?? 'running'),
        notes: json['notes'] as String? ?? '',
        pauseCount: json['pauseCount'] as int? ?? 0,
        distractionCount: json['distractionCount'] as int? ?? 0,
        pomodoroCycle: json['pomodoroCycle'] as int? ?? 1,
        pomodoroPhase: json['pomodoroPhase'] as String? ?? 'work',
      );
}
