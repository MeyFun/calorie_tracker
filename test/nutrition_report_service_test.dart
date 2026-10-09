import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:calorie_tracker/models/food_group.dart';
import 'package:calorie_tracker/models/food_item.dart';
import 'package:calorie_tracker/models/user_profile.dart';
import 'package:calorie_tracker/services/nutrition_report_service.dart';
import 'package:calorie_tracker/utils/calorie_target_storage.dart';

void main() {
  late Directory hiveDirectory;
  late Box settingsBox;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'calorie_tracker_report_test',
    );
    Hive.init(hiveDirectory.path);
    settingsBox = await Hive.openBox('settingsBox');
  });

  tearDown(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('shares consumed and saved target macros for each selected date', () {
    final firstDay = DateTime(2026, 10, 7);
    final secondDay = DateTime(2026, 10, 8);
    final profile = UserProfile(
      fullName: 'Мария Иванова',
      age: 34,
      height: 168,
      weight: 70,
      targetWeight: 60,
      daysToGoal: 90,
      activityFactor: 1.55,
    );
    settingsBox.put('userProfile', profile.toMap());
    nutritionTargetsForDate(settingsBox, firstDay, profile);
    nutritionTargetsForDate(settingsBox, secondDay, profile);

    final changedProfile = UserProfile(
      fullName: profile.fullName,
      weight: 90,
      targetWeight: 90,
      daysToGoal: 0,
    );
    settingsBox.put('userProfile', changedProfile.toMap());

    final food = FoodItem(
      name: 'Овсянка',
      protein: 10,
      fat: 5,
      carbs: 20,
      calories: 150,
      baseWeight: 100,
      weightEaten: 200,
    );
    settingsBox.put('foodJournalMap', {
      '2026-10-07': [
        FoodGroup(groupName: 'Завтрак', items: [food]).toMap(),
      ],
    });

    final report = NutritionReportService().buildReport(
      settingsBox,
      firstDay,
      secondDay,
    );

    expect(report, contains('ФИО: Мария Иванова'));
    expect(report, contains('Возраст: 34 лет'));
    expect(report, contains('Рост: 168 см'));
    expect(report, contains('Текущий вес: 70 кг'));
    expect(report, contains('Целевой вес: 60 кг'));
    expect(report, contains('Срок снижения веса: 90 дней'));
    expect(report, contains('Уровень активности: Умеренная активность'));
    expect(report, contains('Период: 07.10.2026 — 08.10.2026'));
    expect(report, contains('07.10.2026: 300 /'));
    expect(report, contains('Б 20 / 140 г'));
    expect(report, contains('08.10.2026: 0 /'));
    expect(
      report,
      contains('для некоторых прошлых дней нормы БЖУ не были сохранены'),
    );
    expect(report, contains('Калории: 300 /'));
    expect(report, contains('Углеводы: 40 /'));
    expect(
      nutritionTargetsForDate(settingsBox, firstDay, changedProfile).protein,
      profile.targetProtein,
    );
  });

  test('rejects a report range ending before it starts', () {
    expect(
      () => NutritionReportService().buildReport(
        settingsBox,
        DateTime(2026, 10, 9),
        DateTime(2026, 10, 8),
      ),
      throwsArgumentError,
    );
  });
}
