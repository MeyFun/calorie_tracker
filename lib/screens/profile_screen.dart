import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';
import '../utils/calorie_target_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _box = Hive.box('settingsBox');

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _daysToGoalController = TextEditingController();

  late UserProfile _savedProfile;
  late double _selectedActivity;

  final Map<double, String> _activityOptions = {
    1.2: 'Сидячий образ жизни (нет нагрузок)',
    1.375: 'Легкая активность (тренировки 1-3 раза в неделю)',
    1.55: 'Умеренная активность (тренировки 3-5 раз в неделю)',
    1.725: 'Высокая активность (тренировки каждый день)',
  };

  @override
  void initState() {
    super.initState();
    _savedProfile = UserProfile.fromMap(_box.get('userProfile') as Map?);
    _selectedActivity = _savedProfile.activityFactor;
    _setControllers(_savedProfile);
  }

  void _setControllers(UserProfile profile) {
    _nameController.text = profile.fullName;
    _ageController.text = profile.age.toString();
    _heightController.text = profile.height.toStringAsFixed(0);
    _weightController.text = profile.weight.toStringAsFixed(1);
    _targetWeightController.text = profile.targetWeight.toStringAsFixed(1);
    _daysToGoalController.text = profile.daysToGoal.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _daysToGoalController.dispose();
    super.dispose();
  }

  UserProfile get _draftProfile => UserProfile(
        fullName: _nameController.text,
        age: int.tryParse(_ageController.text) ?? _savedProfile.age,
        height:
            double.tryParse(_heightController.text.replaceAll(',', '.')) ??
                _savedProfile.height,
        weight:
            double.tryParse(_weightController.text.replaceAll(',', '.')) ??
                _savedProfile.weight,
        targetWeight: double.tryParse(
              _targetWeightController.text.replaceAll(',', '.'),
            ) ??
            _savedProfile.targetWeight,
        daysToGoal:
            int.tryParse(_daysToGoalController.text) ?? _savedProfile.daysToGoal,
        activityFactor: _selectedActivity,
      );

  void _saveProfile() {
    final profile = _draftProfile;
    _box.put('userProfile', profile.toMap());
    saveTodayCalorieTarget(_box, profile);
    _savedProfile = profile;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Профиль и цель успешно сохранены!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _draftProfile;
    final goalText = profile.daysToGoal <= 0 ||
            profile.targetWeight == profile.weight
        ? 'Норма поддержания веса'
        : profile.targetWeight < profile.weight
            ? 'Норма для снижения веса'
            : 'Норма для набора веса';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль и цели'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ФИО',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Возраст',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Рост (см)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Текущий вес (кг)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _targetWeightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Целевой вес (кг)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _daysToGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'За сколько дней достичь цели?',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              key: ValueKey('profile_activity_$_selectedActivity'),
              initialValue: _selectedActivity,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Уровень активности',
                border: OutlineInputBorder(),
              ),
              items: _activityOptions.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedActivity = value);
              },
            ),
            const Divider(height: 36, thickness: 2),
            Center(
              child: Column(
                children: [
                  Text(
                    goalText,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.dailyCalories} ккал/день',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Целевые КБЖУ в день',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Белки: ${profile.targetProtein} г   '
                    'Жиры: ${profile.targetFat} г   '
                    'Углеводы: ${profile.targetCarbs} г',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Сохранить профиль и цель',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
