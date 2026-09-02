import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timer_desktop/core/providers/database_provider.dart';
import 'package:timer_desktop/core/providers/timer_provider.dart';
import 'package:timer_desktop/core/services/focus_timer_service.dart';
import 'package:timer_desktop/core/storage/app_database.dart';
import 'package:timer_desktop/core/theme/app_theme.dart';
import 'package:timer_desktop/core/widgets/confirm_dialog.dart';
import 'package:timer_desktop/core/widgets/custom_title_bar.dart';
import 'package:timer_desktop/core/widgets/empty_state_widget.dart';
import 'package:timer_desktop/core/widgets/stat_card.dart';

void main() {
  testWidgets('StatCard displays title, value, and subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: StatCard(
            icon: PhosphorIconsRegular.timer,
            title: "Today's Focus Time",
            value: '2h 15m',
            subtitle: 'Goal: 2h',
          ),
        ),
      ),
    );

    expect(find.text("Today's Focus Time"), findsOneWidget);
    expect(find.text('2h 15m'), findsOneWidget);
    expect(find.text('Goal: 2h'), findsOneWidget);
  });

  testWidgets('EmptyStateWidget renders illustration and action button', (WidgetTester tester) async {
    bool actionClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: PhosphorIconsRegular.folderSimple,
            title: 'No Items Found',
            description: 'Start by creating your first entry.',
            actionLabel: 'Add New',
            onAction: () => actionClicked = true,
          ),
        ),
      ),
    );

    expect(find.text('No Items Found'), findsOneWidget);
    expect(find.text('Start by creating your first entry.'), findsOneWidget);
    expect(find.text('Add New'), findsOneWidget);

    await tester.tap(find.text('Add New'));
    expect(actionClicked, true);
  });

  testWidgets('ConfirmDialog displays title, message, and buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConfirmDialog(
            title: 'Delete Entry',
            message: 'Are you sure you want to proceed?',
            confirmLabel: 'Delete Now',
            isDestructive: true,
          ),
        ),
      ),
    );

    expect(find.text('Delete Entry'), findsOneWidget);
    expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
    expect(find.text('Delete Now'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('CustomTitleBar renders app brand and window control buttons', (WidgetTester tester) async {
    final db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    final timerService = FocusTimerService(db);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          timerServiceProvider.overrideWith((ref) => timerService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomTitleBar(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Focus Flow'), findsOneWidget);
    expect(find.byTooltip('Minimize'), findsOneWidget);
    expect(find.byTooltip('Maximize'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
