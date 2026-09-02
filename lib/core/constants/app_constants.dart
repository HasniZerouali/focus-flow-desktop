class AppConstants {
  AppConstants._();

  static const String appName = 'Focus Flow';
  static const String appVersion = '1.0.0';

  // Default Durations in seconds
  static const int defaultFreeFocusSeconds = 0;
  static const int defaultCountdownMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;
  static const int defaultPomodoroCycles = 4;

  // Goals
  static const int defaultDailyFocusMinutes = 120; // 2 hours
  static const int defaultWeeklyFocusMinutes = 600; // 10 hours
  static const int defaultDailyTaskGoal = 3;
  static const int defaultStreakMinMinutes = 20;

  // Distraction Types
  static const List<String> distractionPresets = [
    'Social media',
    'Phone',
    'YouTube',
    'Messages',
    'Browsing',
    'Other',
  ];

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Development', 'color': '6366F1', 'icon': 'code'},
    {'name': 'Study', 'color': '8B5CF6', 'icon': 'bookOpen'},
    {'name': 'Reading', 'color': 'EC4899', 'icon': 'book'},
    {'name': 'Writing', 'color': 'F97316', 'icon': 'pen'},
    {'name': 'Research', 'color': '06B6D4', 'icon': 'magnifyingGlass'},
    {'name': 'Exercise', 'color': '10B981', 'icon': 'barbell'},
    {'name': 'Personal', 'color': '14B8A6', 'icon': 'user'},
    {'name': 'Other', 'color': '64748B', 'icon': 'dotsThree'},
  ];

  // Countdown Presets (Minutes)
  static const List<int> countdownPresets = [15, 25, 45, 60, 90];

  // Window Sizes
  static const double minWindowWidth = 1100.0;
  static const double minWindowHeight = 700.0;
  static const double defaultWindowWidth = 1280.0;
  static const double defaultWindowHeight = 820.0;

  // Keyboard Shortcuts
  static const String shortcutStartPause = 'Ctrl + Shift + S';
  static const String shortcutFinish = 'Ctrl + Shift + F';
  static const String shortcutPomodoro = 'Ctrl + Shift + P';
  static const String shortcutTasks = 'Ctrl + Shift + T';
}
