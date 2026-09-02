# Focus Flow — Windows Desktop Productivity Application

[![Flutter](https://img.shields.io/badge/Flutter-3.35.2-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.0-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20x64-0078D6?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-21%20Passing-brightgreen.svg)]()

**Focus Flow** is a high-performance, native Windows desktop productivity and focus session management application built with **Flutter Desktop**, **Riverpod**, and **Drift SQLite**. Designed with uncompromising speed, rich desktop aesthetics, and deep Windows OS integration, it enables you to start focusing in under 5 seconds from cold launch.

---

## 🚀 Key Features

### 1. ⚡ Instant Focus & Sleep-Proof Engine
* **< 5-Second Cold Launch to Timer**: Type your task, select an optional category, and hit `Enter` or click **START FOCUS**.
* **Mathematical Elapsed Calculation**: The timer engine **never relies on second ticks or simple integer counter increments**. It calculates elapsed time dynamically via timestamp differences:
  $$\text{Elapsed} = \text{AccumulatedDuration} + (\text{Now} - \text{StartedAt})$$
* **OS Sleep & App Crash Recovery**: Active session state is continuously synced to local SQLite key-value recovery storage. If Windows sleeps, hibernates, restarts, or the app crashes, the session is accurately recovered upon restart without dropping a single second.
* **Minimal Distraction-Free Mode**: A dedicated single-keystroke full-window focus mode displaying only the task name and a clean oversized timer clock.
* **Distraction Logger**: Log internal and external interruptions (e.g., Slack, Email, Phone, Urgent Task) mid-session without stopping your focus flow.
* **Session Completion Flow**: Rate your session from 1 to 5 stars, record insights or notes, and save directly to your historical record.

### 2. 🍅 Pomodoro Technique Mode
* **Visual Progress Ring**: Smooth circular animation rendering remaining minutes and seconds.
* **Phase Transitions**: Automated progression through **Focus (25m)**, **Short Break (5m)**, and **Long Break (15m)** after every 4 completed intervals.
* **Configurable Durations**: Customize work, short break, and long break intervals in Settings.
* **Cycle Tracking**: Live visual dot badges indicating your progress toward the 4-cycle long break.

### 3. 📋 Deep Task Management
* **Direct "Start Focus" Launcher**: Launch a dedicated focus session linked directly to any pending task with a single click.
* **Priority Matrix**: Organize tasks by High, Medium, or Low priority badges.
* **Category Association**: Group tasks by preset or custom categories with custom hex colors and Phosphor icons.
* **Accumulated Focus Time**: Automatically tracks cumulative focus seconds logged per task over its lifetime.

### 4. 📊 7-Day Analytics & Motivational Scoring
* **Interactive 7-Day Bar Charts**: Built with `fl_chart`, visualizing daily focus minutes across the current week.
* **Category Distribution**: Visual breakdown showing where your time was invested.
* **Productivity Score (0–100)**: Motivational formula factoring in daily target completion ratio (40 pts), session consistency (25 pts), task completions (20 pts), goal achievement boost (10 pts), with deductions for recorded distractions.
* **Weekly Performance Metrics**: Track weekly total hours, daily averages, best day, and top focus category.

### 5. 🔥 Streaks & Daily Goals
* **Consecutive Day Streak Tracker**: Automatically tracks consecutive days where you met your configurable daily focus threshold (e.g., $\ge 20$ minutes).
* **Live Progress Bars**: Real-time tracking of today's focus minutes vs. daily goal and completed tasks vs. task goal.
* **Celebratory Badges**: Visual recognition when daily targets are achieved.

### 6. 🪟 Deep Native Windows Desktop Integration
* **Custom Frameless Title Bar**: Sleek draggable window header (`DragToMoveArea`) with minimize, maximize, and close controls, featuring a live timer pill visible when running.
* **System Tray Integration**:
  * Minimize to Windows notification area tray on window close.
  * Right-click tray menu with options: *Open Focus Flow*, *Pause/Resume*, *Start Focus*, and *Quit*.
  * Hover tooltip reflecting current timer state and remaining time.
* **Windows Native Toast Notifications**: High-priority notifications via WinToast when sessions complete or Pomodoro break phases end.
* **Launch at Windows Startup**: Automatic registry registration to launch Focus Flow upon Windows user login.
* **Global Keyboard Shortcuts**:
  * `Ctrl + Shift + S`: Start, pause, or resume the active timer.
  * `Ctrl + Shift + F`: Finish current session and open the rating dialog.
  * `Ctrl + Shift + P`: Quick navigate to Pomodoro.
  * `Ctrl + Shift + T`: Quick navigate to Tasks.

### 7. 🔒 100% Offline, Private, & Portable
* **Zero Telemetry or Cloud Dependency**: All database records reside locally on your machine in SQLite.
* **JSON Backup & Restore**: Export your full database to clipboard or file; validated schema import protects against data corruption.
* **RFC-4180 CSV Export**: Export historical focus sessions for external analysis in Excel, Google Sheets, or Notion.

---

## 🛠️ Architecture & Technology Stack

```
timer_desktop/
├── lib/
│   ├── app/
│   │   ├── app.dart                    # MaterialApp.router, Global Keyboard Shortcuts, Theme
│   │   └── router.dart                 # GoRouter ShellRoute with custom title bar & sidebar
│   ├── core/
│   │   ├── constants/                  # App constraints, shortcuts, duration presets
│   │   ├── providers/                  # Riverpod providers (Timer, DB, Sessions, Goals, etc.)
│   │   ├── services/
│   │   │   ├── focus_timer_service.dart # Central sleep-proof timer engine (DateTime math)
│   │   │   ├── backup_service.dart     # JSON validation, import/export, RFC-4180 CSV
│   │   │   ├── notification_service.dart# Windows native WinToast integration
│   │   │   ├── startup_service.dart    # Windows autostart registry integration
│   │   │   ├── tray_service.dart       # Windows system tray menu and lifecycle
│   │   │   └── window_service.dart     # window_manager sizing and frameless titlebar
│   │   ├── storage/
│   │   │   ├── app_database.dart       # Drift SQLite schema, DAOs, migration seeds
│   │   │   ├── app_database.g.dart     # Generated Drift code
│   │   │   └── models.dart             # Domain models and enums
│   │   ├── theme/                      # AppColors, AppSpacing, AppTypography, AppTheme
│   │   ├── utils/                      # DurationFormatters, DateFormatters, ProductivityScore
│   │   └── widgets/                    # CustomTitleBar, SidebarNavigation, StatCard, etc.
│   ├── features/
│   │   ├── dashboard/                  # Quick start, active banner, stats, recent list
│   │   ├── focus/                      # Stopwatch & Countdown, Minimal view, Sheets
│   │   ├── goals/                      # Streaks, Daily & Weekly goal progress
│   │   ├── history/                    # Day-grouped history, filter chips, session detail
│   │   ├── pomodoro/                   # Pomodoro phase transitions and circular timer ring
│   │   ├── settings/                   # Appearance, Windows toggles, backup/export
│   │   ├── statistics/                 # 7-Day fl_chart bars, score card, category totals
│   │   └── tasks/                      # Tasks list, add/edit dialog, priority badges
│   └── main.dart                       # Native service initialization and app entry
├── test/
│   ├── unit/                           # 17 Unit tests (Timer, Math, Streaks, Backup, Score)
│   └── widget_test.dart                # 4 Widget tests (TitleBar, StatCard, EmptyState, Dialog)
└── windows/                            # Native Windows runner C++ source and CMake scripts
```

---

## 💻 Prerequisites & Setup

### Requirements
* **Operating System**: Windows 10 or Windows 11 (64-bit)
* **Flutter SDK**: version 3.35.0+ (stable channel)
* **Dart SDK**: version 3.9.0+
* **Visual Studio**: Visual Studio 2022 or 2026 with **"Desktop development with C++"** workload installed.

### Verification
Run Flutter doctor to verify your C++ desktop toolchain:
```bash
flutter doctor -v
```
Ensure that `[√] Visual Studio - develop Windows apps` is marked green.

---

## 🏃 Building and Running

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run in Debug Mode
```bash
flutter run -d windows
```

### 3. Run Automated Tests
```bash
flutter test
```
*Executes all 21 unit and widget tests covering timer calculation math, sleep recovery, streak continuity, backup schema validation, and desktop UI components.*

### 4. Build Production Executable (`.exe`)
For Visual Studio 2026 / CMake:
```bash
# Generate build files
& 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' -S windows -B build\windows\x64 -G "Visual Studio 18 2026" -A x64 -DFLUTTER_TARGET_PLATFORM=windows-x64

# Compile Release binary
& 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' --build build\windows\x64 --config Release
```
Or for standard Flutter Windows toolchain:
```bash
flutter build windows
```
The compiled executable and required runtime libraries will be located at:
```
build\windows\x64\runner\Release\timer_desktop.exe
```

---

## ⌨️ Keyboard Shortcuts Reference

| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| `Ctrl + Shift + S` | Toggle Start / Pause / Resume timer | Global |
| `Ctrl + Shift + F` | Finish active session and open Rating sheet | Global |
| `Ctrl + Shift + P` | Open Pomodoro Screen | Global |
| `Ctrl + Shift + T` | Open Tasks Screen | Global |
| `Space` | Pause / Resume (when on Focus screen) | In-App |
| `Esc` | Exit Minimal Distraction-Free view | In-App |

---

## 🗄️ Database Location

Data is stored locally in an embedded SQLite database using Drift:
* **Database Name**: `focus_flow_desktop_db.sqlite`
* **Path**: `%APPDATA%\com.focusflow.timerDesktop\focus_flow_desktop_db.sqlite` (or the app's `getApplicationDocumentsDirectory()`)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
