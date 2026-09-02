import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../storage/app_database.dart';
import '../storage/models.dart';
import '../../features/pomodoro/domain/pomodoro_phase.dart';
import 'notification_service.dart';
import 'tray_service.dart';

class TimerSnapshot {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String? taskId;
  final String? taskTitle;
  final TimerMode mode;
  final SessionState state;
  final int targetDurationSeconds;
  final int elapsedSeconds;
  final int remainingSeconds;
  final int pauseCount;
  final int distractionCount;
  final String notes;
  final int pomodoroCycle;
  final PomodoroPhase pomodoroPhase;

  const TimerSnapshot({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    this.taskId,
    this.taskTitle,
    required this.mode,
    required this.state,
    required this.targetDurationSeconds,
    required this.elapsedSeconds,
    required this.remainingSeconds,
    required this.pauseCount,
    required this.distractionCount,
    required this.notes,
    required this.pomodoroCycle,
    required this.pomodoroPhase,
  });

  bool get isRunning => state == SessionState.running;
  bool get isPaused => state == SessionState.paused;
  bool get isActive => state.isActive;
}

class FocusTimerService extends ChangeNotifier {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  FocusTimerService(this._db);

  String _id = '';
  String _title = '';
  String _categoryId = 'Development';
  String _categoryName = 'Development';
  String? _taskId;
  String? _taskTitle;
  TimerMode _mode = TimerMode.free;
  SessionState _state = SessionState.idle;

  DateTime _startedAt = DateTime.now();
  DateTime _initialSessionStart = DateTime.now();
  int _accumulatedSeconds = 0;
  int _targetDurationSeconds = 0;

  int _pauseCount = 0;
  int _distractionCount = 0;
  String _notes = '';

  // Pomodoro
  int _pomodoroCycle = 1;
  PomodoroPhase _pomodoroPhase = PomodoroPhase.work;

  Timer? _ticker;

  // Scoped notifier for second-by-second updates
  final ValueNotifier<int> elapsedNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> remainingNotifier = ValueNotifier<int>(0);

  TimerSnapshot get snapshot => TimerSnapshot(
        id: _id,
        title: _title,
        categoryId: _categoryId,
        categoryName: _categoryName,
        taskId: _taskId,
        taskTitle: _taskTitle,
        mode: _mode,
        state: _state,
        targetDurationSeconds: _targetDurationSeconds,
        elapsedSeconds: currentElapsedSeconds,
        remainingSeconds: currentRemainingSeconds,
        pauseCount: _pauseCount,
        distractionCount: _distractionCount,
        notes: _notes,
        pomodoroCycle: _pomodoroCycle,
        pomodoroPhase: _pomodoroPhase,
      );

  int get currentElapsedSeconds {
    if (_state == SessionState.idle) return 0;
    if (_state == SessionState.paused) return _accumulatedSeconds;

    final now = DateTime.now();
    final runningSegment = now.difference(_startedAt).inSeconds;
    return _accumulatedSeconds + (runningSegment > 0 ? runningSegment : 0);
  }

  int get currentRemainingSeconds {
    if (_mode == TimerMode.free) return 0;
    final remaining = _targetDurationSeconds - currentElapsedSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // --- Startup / Recovery ---
  Future<void> restoreIfActive() async {
    final recovery = await _db.getActiveSession();
    if (recovery == null) return;

    _id = recovery.id;
    _title = recovery.title;
    _categoryId = recovery.categoryId;
    _categoryName = recovery.categoryName;
    _taskId = recovery.taskId;
    _taskTitle = recovery.taskTitle;
    _mode = recovery.mode;
    _targetDurationSeconds = recovery.targetDurationSeconds;
    _initialSessionStart = recovery.startedAt;
    _pauseCount = recovery.pauseCount;
    _distractionCount = recovery.distractionCount;
    _notes = recovery.notes;
    _pomodoroCycle = recovery.pomodoroCycle;
    _pomodoroPhase = PomodoroPhase.values.firstWhere(
      (p) => p.name == recovery.pomodoroPhase,
      orElse: () => PomodoroPhase.work,
    );

    if (recovery.state == SessionState.paused) {
      _state = SessionState.paused;
      _accumulatedSeconds = recovery.accumulatedSeconds;
      _startedAt = recovery.pausedAt ?? DateTime.now();
    } else {
      // Was running when app closed/slept
      _accumulatedSeconds = recovery.accumulatedSeconds;
      _startedAt = recovery.startedAt;
      _state = SessionState.running;

      // Check if countdown target passed during OS sleep or app shutdown
      if (_mode != TimerMode.free && currentElapsedSeconds >= _targetDurationSeconds) {
        _state = SessionState.completed;
        _accumulatedSeconds = _targetDurationSeconds;
        await _db.clearActiveSession();
        _onTargetReached(silent: true);
        notifyListeners();
        return;
      }

      _startTicker();
    }

    _updateNotifiers();
    TrayService.instance.updateFocusState(isRunning: _state == SessionState.running);
    notifyListeners();
  }

  // --- Start Session ---
  Future<void> startSession({
    required String title,
    required String categoryId,
    required String categoryName,
    String? taskId,
    String? taskTitle,
    TimerMode mode = TimerMode.free,
    int targetDurationMinutes = 25,
    int pomodoroCycle = 1,
    PomodoroPhase pomodoroPhase = PomodoroPhase.work,
  }) async {
    _id = _uuid.v4();
    _title = title.trim().isEmpty ? 'Quick Focus' : title.trim();
    _categoryId = categoryId;
    _categoryName = categoryName;
    _taskId = taskId;
    _taskTitle = taskTitle;
    _mode = mode;
    _targetDurationSeconds = (mode == TimerMode.free) ? 0 : (targetDurationMinutes * 60);
    _initialSessionStart = DateTime.now();
    _startedAt = _initialSessionStart;
    _accumulatedSeconds = 0;
    _pauseCount = 0;
    _distractionCount = 0;
    _notes = '';
    _pomodoroCycle = pomodoroCycle;
    _pomodoroPhase = pomodoroPhase;
    _state = SessionState.running;

    await _persistActiveState();
    _startTicker();
    _updateNotifiers();

    TrayService.instance.updateFocusState(isRunning: true);
    notifyListeners();
  }

  // --- Pause Session ---
  Future<void> pause() async {
    if (_state != SessionState.running) return;

    final now = DateTime.now();
    _accumulatedSeconds += now.difference(_startedAt).inSeconds;
    _startedAt = now;
    _pauseCount++;
    _state = SessionState.paused;

    _stopTicker();
    _updateNotifiers();
    await _persistActiveState();

    TrayService.instance.updateFocusState(isRunning: false);
    notifyListeners();
  }

  // --- Resume Session ---
  Future<void> resume() async {
    if (_state != SessionState.paused) return;

    _startedAt = DateTime.now();
    _state = SessionState.running;

    _startTicker();
    _updateNotifiers();
    await _persistActiveState();

    TrayService.instance.updateFocusState(isRunning: true);
    notifyListeners();
  }

  // --- Add Distraction ---
  Future<void> logDistraction(String type, {String note = ''}) async {
    _distractionCount++;
    final distraction = DistractionModel(
      id: _uuid.v4(),
      sessionId: _id,
      type: type,
      timestamp: DateTime.now(),
      note: note,
    );

    await _db.insertDistraction(distraction);
    await _persistActiveState();
    notifyListeners();
  }

  // --- Update Notes ---
  Future<void> updateNotes(String newNotes) async {
    _notes = newNotes;
    await _persistActiveState();
    notifyListeners();
  }

  // --- Finish Session ---
  Future<FocusSessionModel> finishSession({int? rating, String? notes}) async {
    final finalDuration = currentElapsedSeconds;
    final finalNotes = notes ?? _notes;

    _state = SessionState.completed;
    _stopTicker();

    final session = FocusSessionModel(
      id: _id,
      title: _title,
      categoryId: _categoryId,
      categoryName: _categoryName,
      taskId: _taskId,
      taskTitle: _taskTitle,
      startedAt: _initialSessionStart,
      endedAt: DateTime.now(),
      durationSeconds: finalDuration,
      targetDurationSeconds: _targetDurationSeconds,
      mode: _mode,
      state: SessionState.completed,
      rating: rating,
      notes: finalNotes,
      pauseCount: _pauseCount,
      distractionCount: _distractionCount,
    );

    // Persist to database history
    await _db.insertSession(session);

    // Attach completed focus time to task if linked
    if (_taskId != null && _taskId!.isNotEmpty) {
      await _db.addFocusTimeToTask(_taskId!, finalDuration);
    }

    // Clear active recovery state
    await _db.clearActiveSession();

    _resetState();
    TrayService.instance.updateFocusState(isRunning: false);
    notifyListeners();

    return session;
  }

  // --- Cancel Session ---
  Future<void> cancelSession() async {
    _stopTicker();
    await _db.clearActiveSession();
    _resetState();
    TrayService.instance.updateFocusState(isRunning: false);
    notifyListeners();
  }

  // --- Internal Helpers ---
  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateNotifiers();

      if (_mode != TimerMode.free && currentElapsedSeconds >= _targetDurationSeconds) {
        _onTargetReached();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _updateNotifiers() {
    elapsedNotifier.value = currentElapsedSeconds;
    remainingNotifier.value = currentRemainingSeconds;
  }

  void _onTargetReached({bool silent = false}) {
    _stopTicker();
    _state = SessionState.completed;
    _updateNotifiers();

    if (!silent) {
      final mins = (_targetDurationSeconds / 60).round();
      if (_mode == TimerMode.pomodoro) {
        final nextPhase = _pomodoroPhase.isWork ? 'Break Time!' : 'Focus Time!';
        NotificationService.instance.notifyPomodoroPhase(
          phaseName: _pomodoroPhase.label,
          message: 'Phase finished! Time for $nextPhase',
        );
      } else {
        NotificationService.instance.notifySessionCompleted(
          sessionTitle: _title,
          durationMinutes: mins,
        );
      }
    }

    notifyListeners();
  }

  Future<void> _persistActiveState() async {
    final recovery = ActiveSessionRecovery(
      id: _id,
      title: _title,
      categoryId: _categoryId,
      categoryName: _categoryName,
      taskId: _taskId,
      taskTitle: _taskTitle,
      startedAt: _startedAt,
      pausedAt: _state == SessionState.paused ? _startedAt : null,
      accumulatedSeconds: _accumulatedSeconds,
      targetDurationSeconds: _targetDurationSeconds,
      mode: _mode,
      state: _state,
      notes: _notes,
      pauseCount: _pauseCount,
      distractionCount: _distractionCount,
      pomodoroCycle: _pomodoroCycle,
      pomodoroPhase: _pomodoroPhase.name,
    );

    await _db.saveActiveSession(recovery);
  }

  void _resetState() {
    _id = '';
    _title = '';
    _state = SessionState.idle;
    _accumulatedSeconds = 0;
    _targetDurationSeconds = 0;
    _pauseCount = 0;
    _distractionCount = 0;
    _notes = '';
    _taskId = null;
    _taskTitle = null;
    _updateNotifiers();
  }

  @override
  void dispose() {
    _stopTicker();
    elapsedNotifier.dispose();
    remainingNotifier.dispose();
    super.dispose();
  }
}
