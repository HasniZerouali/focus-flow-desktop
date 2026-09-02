import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum PomodoroPhase {
  work,
  shortBreak,
  longBreak,
}

extension PomodoroPhaseX on PomodoroPhase {
  String get label {
    switch (this) {
      case PomodoroPhase.work:
        return 'Focus Work';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  bool get isWork => this == PomodoroPhase.work;
  bool get isBreak => this == PomodoroPhase.shortBreak || this == PomodoroPhase.longBreak;

  Color get color {
    switch (this) {
      case PomodoroPhase.work:
        return AppColors.primary;
      case PomodoroPhase.shortBreak:
        return AppColors.success;
      case PomodoroPhase.longBreak:
        return AppColors.info;
    }
  }
}
