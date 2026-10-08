import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

int calculateDiaryCalorieTarget(UserProfile? profile) {
  if (profile == null) return 2500;

  if (profile.daysToGoal > 0) {
    return profile.dailyCalories;
  }
  return profile.maintenanceCalories;
}

int calorieTargetForDate(Box box, DateTime date, UserProfile? profile) {
  final key = _dateKey(date);
  final rawTargets = box.get('dailyCalorieTargets') as Map? ?? {};
  final savedTarget = rawTargets[key];
  if (savedTarget is num) return savedTarget.round();

  final target = calculateDiaryCalorieTarget(profile);
  _saveTarget(box, rawTargets, key, target);
  return target;
}

void saveTodayCalorieTarget(Box box, UserProfile profile) {
  final rawTargets = box.get('dailyCalorieTargets') as Map? ?? {};
  _saveTarget(box, rawTargets, _dateKey(DateTime.now()), calculateDiaryCalorieTarget(profile));
}

void _saveTarget(Box box, Map<dynamic, dynamic> rawTargets, String key, int target) {
  final targets = <String, dynamic>{
    for (final entry in rawTargets.entries) entry.key.toString(): entry.value,
  };
  targets[key] = target;
  box.put('dailyCalorieTargets', targets);
}
