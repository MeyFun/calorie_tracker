import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/food_group.dart';
import '../models/user_profile.dart';
import '../utils/calorie_target_storage.dart';

class NutritionReportService {
  String buildReport(
    Box settingsBox,
    DateTime start,
    DateTime end, {
    UserProfile? profile,
  }) {
    final firstDay = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);
    if (lastDay.isBefore(firstDay)) {
      throw ArgumentError('Дата окончания не может быть раньше даты начала.');
    }

    final reportProfile =
        profile ?? UserProfile.fromMap(settingsBox.get('userProfile') as Map?);
    final rawJournal = settingsBox.get('foodJournalMap') as Map? ?? {};
    final dateFormat = DateFormat('dd.MM.yyyy');
    final activityName = _activityName(reportProfile.activityFactor);
    final goalDescription = reportProfile.targetWeight < reportProfile.weight
        ? 'Срок снижения веса'
        : reportProfile.targetWeight > reportProfile.weight
        ? 'Срок набора веса'
        : 'Срок достижения цели';
    final lines = <String>[
      'Статистика питания',
      '',
      'Данные человека:',
      'ФИО: ${reportProfile.fullName.trim().isEmpty ? 'не указано' : reportProfile.fullName.trim()}',
      'Возраст: ${reportProfile.age} лет',
      'Рост: ${_number(reportProfile.height)} см',
      'Текущий вес: ${_number(reportProfile.weight)} кг',
      'Целевой вес: ${_number(reportProfile.targetWeight)} кг',
      '$goalDescription: ${reportProfile.daysToGoal} дней',
      'Уровень активности: $activityName',
      '',
      'Период: ${dateFormat.format(firstDay)} — ${dateFormat.format(lastDay)}',
      '',
      'По дням (потреблено / цель):',
    ];

    var consumedCalories = 0.0;
    var consumedProtein = 0.0;
    var consumedFat = 0.0;
    var consumedCarbs = 0.0;
    var targetCalories = 0;
    var targetProtein = 0;
    var targetFat = 0;
    var targetCarbs = 0;
    var hasEstimatedMacroTargets = false;

    for (
      var day = firstDay;
      !day.isAfter(lastDay);
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      final key = _dateKey(day);
      final rawGroups = rawJournal[key] as List? ?? [];
      final groups = rawGroups
          .map((group) => FoodGroup.fromMap(group as Map))
          .toList();
      final calories = groups.fold<double>(
        0,
        (sum, group) => sum + group.totalCalories,
      );
      final protein = groups.fold<double>(
        0,
        (sum, group) => sum + group.totalProtein,
      );
      final fat = groups.fold<double>(
        0,
        (sum, group) => sum + group.totalFat,
      );
      final carbs = groups.fold<double>(
        0,
        (sum, group) => sum + group.totalCarbs,
      );
      final targets = nutritionTargetsForDate(settingsBox, day, reportProfile);
      hasEstimatedMacroTargets |= targets.macrosEstimated;

      consumedCalories += calories;
      consumedProtein += protein;
      consumedFat += fat;
      consumedCarbs += carbs;
      targetCalories += targets.calories;
      targetProtein += targets.protein;
      targetFat += targets.fat;
      targetCarbs += targets.carbs;

      lines.add(
        '${dateFormat.format(day)}: '
        '${_number(calories)} / ${targets.calories} ккал; '
        'Б ${_number(protein)} / ${targets.protein} г; '
        'Ж ${_number(fat)} / ${targets.fat} г; '
        'У ${_number(carbs)} / ${targets.carbs} г',
      );
    }

    if (hasEstimatedMacroTargets) {
      lines
        ..add('')
        ..add(
          'Примечание: для некоторых прошлых дней нормы БЖУ не были сохранены; '
          'для них показаны текущие цели профиля.',
        );
    }

    lines
      ..add('')
      ..add('Итого потреблено / цель за период:')
      ..add(
        'Калории: ${_number(consumedCalories)} / $targetCalories ккал',
      )
      ..add('Белки: ${_number(consumedProtein)} / $targetProtein г')
      ..add('Жиры: ${_number(consumedFat)} / $targetFat г')
      ..add('Углеводы: ${_number(consumedCarbs)} / $targetCarbs г');
    return lines.join('\n');
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _activityName(double factor) => switch (factor) {
    1.2 => 'Сидячий образ жизни (нет нагрузок)',
    1.375 => 'Лёгкая активность (тренировки 1–3 раза в неделю)',
    1.55 => 'Умеренная активность (тренировки 3–5 раз в неделю)',
    1.725 => 'Высокая активность (тренировки каждый день)',
    _ => 'Коэффициент ${_number(factor)}',
  };

  static String _number(double value) =>
      NumberFormat('#,##0.#', 'ru').format(value);
}
