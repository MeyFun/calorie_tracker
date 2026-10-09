import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

bool _isBeforeToday(DateTime date) {
  final today = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).isBefore(DateTime(today.year, today.month, today.day));
}

class NutritionTargets {
  const NutritionTargets({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.macrosEstimated = false,
  });

  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final bool macrosEstimated;

  Map<String, dynamic> toMap() => {
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'macrosEstimated': macrosEstimated,
  };
}

int calculateDiaryCalorieTarget(UserProfile? profile) {
  if (profile == null) return 2500;

  if (profile.daysToGoal > 0) {
    return profile.dailyCalories;
  }
  return profile.maintenanceCalories;
}

int calorieTargetForDate(Box box, DateTime date, UserProfile? profile) {
  return nutritionTargetsForDate(box, date, profile).calories;
}

NutritionTargets nutritionTargetsForDate(
  Box box,
  DateTime date,
  UserProfile? profile,
) {
  final key = _dateKey(date);
  final rawSnapshots = box.get('dailyNutritionTargets') as Map? ?? {};
  final savedSnapshot = rawSnapshots[key];
  if (savedSnapshot is Map) {
    final calories = savedSnapshot['calories'];
    final protein = savedSnapshot['protein'];
    final fat = savedSnapshot['fat'];
    final carbs = savedSnapshot['carbs'];
    if (calories is num && protein is num && fat is num && carbs is num) {
      return NutritionTargets(
        calories: calories.round(),
        protein: protein.round(),
        fat: fat.round(),
        carbs: carbs.round(),
        macrosEstimated: savedSnapshot['macrosEstimated'] == true,
      );
    }
  }

  final rawCalorieTargets = box.get('dailyCalorieTargets') as Map? ?? {};
  final savedCalories = rawCalorieTargets[key];
  final targets = NutritionTargets(
    calories: savedCalories is num
        ? savedCalories.round()
        : calculateDiaryCalorieTarget(profile),
    protein: profile?.targetProtein ?? 150,
    fat: profile?.targetFat ?? 80,
    carbs: profile?.targetCarbs ?? 250,
    macrosEstimated: _isBeforeToday(date),
  );
  _saveSnapshot(box, rawSnapshots, key, targets);
  return targets;
}

void saveTodayCalorieTarget(Box box, UserProfile profile) {
  final dateKey = _dateKey(DateTime.now());
  final targets = NutritionTargets(
    calories: calculateDiaryCalorieTarget(profile),
    protein: profile.targetProtein,
    fat: profile.targetFat,
    carbs: profile.targetCarbs,
    macrosEstimated: false,
  );
  final rawCalorieTargets = box.get('dailyCalorieTargets') as Map? ?? {};
  _saveTarget(box, rawCalorieTargets, dateKey, targets.calories);
  final rawSnapshots = box.get('dailyNutritionTargets') as Map? ?? {};
  _saveSnapshot(box, rawSnapshots, dateKey, targets);
}

void _saveTarget(
  Box box,
  Map<dynamic, dynamic> rawTargets,
  String key,
  int target,
) {
  final targets = <String, dynamic>{
    for (final entry in rawTargets.entries) entry.key.toString(): entry.value,
  };
  targets[key] = target;
  box.put('dailyCalorieTargets', targets);
}

void _saveSnapshot(
  Box box,
  Map<dynamic, dynamic> rawSnapshots,
  String key,
  NutritionTargets targets,
) {
  final snapshots = <String, dynamic>{
    for (final entry in rawSnapshots.entries) entry.key.toString(): entry.value,
  };
  snapshots[key] = targets.toMap();
  box.put('dailyNutritionTargets', snapshots);
}
