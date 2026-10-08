import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calorie_tracker/main.dart';
import 'package:calorie_tracker/models/user_profile.dart';
import 'package:calorie_tracker/utils/calorie_target_storage.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'calorie_tracker_test',
    );
    Hive.init(hiveDirectory.path);
    await Hive.openBox('settingsBox');
    await Hive.openBox('templatesBox');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('keeps a separate calorie target snapshot for each date', () {
    final date = DateTime(2026, 10, 8);
    final originalProfile = UserProfile(
      weight: 90,
      targetWeight: 80,
      daysToGoal: 84,
    );
    final originalTarget = calorieTargetForDate(
      Hive.box('settingsBox'),
      date,
      originalProfile,
    );

    final changedProfile = UserProfile(
      weight: 75,
      targetWeight: 80,
      daysToGoal: 84,
    );

    expect(
      calorieTargetForDate(Hive.box('settingsBox'), date, changedProfile),
      originalTarget,
    );
    expect(
      calorieTargetForDate(
        Hive.box('settingsBox'),
        date.add(const Duration(days: 1)),
        changedProfile,
      ),
      calculateDiaryCalorieTarget(changedProfile),
    );
  });

  test('migrates the previously saved goal duration from weeks to days', () {
    final profile = UserProfile.fromMap({
      'weight': 90,
      'targetWeight': 80,
      'weeksToGoal': 12,
    });

    expect(profile.daysToGoal, 84);
  });

  testWidgets('shows the diary and opens the profile tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CalorieTrackerApp());

    expect(find.text('Дневник: Сегодня'), findsOneWidget);

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();

    expect(find.text('Профиль и цели'), findsOneWidget);
    expect(find.text('За сколько дней достичь цели?'), findsOneWidget);
    expect(find.text('Целевые КБЖУ в день'), findsOneWidget);
  });
}
