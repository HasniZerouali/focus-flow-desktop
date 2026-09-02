enum SessionState {
  idle,
  running,
  paused,
  completed,
  cancelled,
}

extension SessionStateX on SessionState {
  bool get isRunning => this == SessionState.running;
  bool get isPaused => this == SessionState.paused;
  bool get isActive => this == SessionState.running || this == SessionState.paused;
  bool get isCompleted => this == SessionState.completed;
  bool get isCancelled => this == SessionState.cancelled;
  bool get isIdle => this == SessionState.idle;

  String get label {
    switch (this) {
      case SessionState.idle:
        return 'Idle';
      case SessionState.running:
        return 'Focusing';
      case SessionState.paused:
        return 'Paused';
      case SessionState.completed:
        return 'Completed';
      case SessionState.cancelled:
        return 'Cancelled';
    }
  }
}
