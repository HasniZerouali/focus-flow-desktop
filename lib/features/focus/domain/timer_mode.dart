enum TimerMode {
  free,
  countdown,
  pomodoro,
}

extension TimerModeX on TimerMode {
  bool get isFree => this == TimerMode.free;
  bool get isCountdown => this == TimerMode.countdown;
  bool get isPomodoro => this == TimerMode.pomodoro;

  String get label {
    switch (this) {
      case TimerMode.free:
        return 'Free Focus';
      case TimerMode.countdown:
        return 'Countdown';
      case TimerMode.pomodoro:
        return 'Pomodoro';
    }
  }
}
