import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _box = Hive.box('settingsBox');
  
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _weeksController = TextEditingController();
  final _heightController = TextEditingController();
  
  double _activityFactor = 1.375;
  int _resultCalories = 2000;

  // Флаг для первой инициализации полей при открытии экрана
  bool _isInitialized = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _weeksController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Метод заполнения контроллеров актуальными данными из Hive
  void _updateControllersFromProfile(UserProfile profile) {
    _fullNameController.text = profile.fullName;
    _ageController.text = profile.age.toString();
    _weightController.text = profile.weight.toStringAsFixed(1);
    _targetWeightController.text = profile.targetWeight.toStringAsFixed(1);
    _weeksController.text = profile.weeksToGoal.toString();
    _heightController.text = profile.height.toStringAsFixed(0);
    _activityFactor = profile.activityFactor;
    _resultCalories = profile.dailyCalories;
    _isInitialized = true;
  }

  // Проверяем: изменились ли критические данные на другом экране
  bool _hasExternalChanges(UserProfile liveProfile) {
    final currentInputWeight = double.tryParse(_weightController.text) ?? 0.0;
    final currentInputHeight = double.tryParse(_heightController.text) ?? 0.0;
    final currentInputAge = int.tryParse(_ageController.text) ?? 0;
    final currentInputName = _fullNameController.text;

    return (liveProfile.weight - currentInputWeight).abs() > 0.09 ||
           (liveProfile.height - currentInputHeight).abs() > 0.09 ||
           liveProfile.age != currentInputAge ||
           liveProfile.fullName != currentInputName;
  }

  void _calculateTarget() {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double target = double.tryParse(_targetWeightController.text) ?? 0;
    int weeks = int.tryParse(_weeksController.text) ?? 0;
    int age = int.tryParse(_ageController.text) ?? 20;
    double height = double.tryParse(_heightController.text) ?? 175;

    if (weight > 0 && target > 0 && weeks > 0) {
      final tempProfile = UserProfile(
        fullName: _fullNameController.text,
        age: age,
        weight: weight,
        targetWeight: target,
        weeksToGoal: weeks,
        height: height,
        activityFactor: _activityFactor,
      );
      setState(() {
        _resultCalories = tempProfile.dailyCalories;
      });
    }
  }

  void _saveProfile() {
    double weight = double.tryParse(_weightController.text) ?? 0;
    double target = double.tryParse(_targetWeightController.text) ?? 0;
    int weeks = int.tryParse(_weeksController.text) ?? 0;
    int age = int.tryParse(_ageController.text) ?? 20;
    double height = double.tryParse(_heightController.text) ?? 175;

    final profile = UserProfile(
      fullName: _fullNameController.text,
      age: age,
      weight: weight,
      targetWeight: target,
      weeksToGoal: weeks,
      height: height,
      activityFactor: _activityFactor,
    );

    _box.put('userProfile', profile.toMap());
    
    // ЗАЩИТА: проверяем, что виджет всё еще в дереве
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Профиль и цель успешно сохранены!'), 
        backgroundColor: Colors.green
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка профиля и цели'), 
        backgroundColor: Colors.green, 
        foregroundColor: Colors.white
      ),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(keys: ['userProfile']),
        builder: (context, Box box, child) {
          final raw = box.get('userProfile');
          
          if (raw != null) {
            final liveProfile = UserProfile.fromMap(raw as Map);
            
            if (!_isInitialized || _hasExternalChanges(liveProfile)) {
              _updateControllersFromProfile(liveProfile);
            }
          }

          // На лету вычисляем текст подсказки в зависимости от направления цели
          double currentW = double.tryParse(_weightController.text) ?? 0;
          double targetW = double.tryParse(_targetWeightController.text) ?? 0;

          String calorieLabel = 'Ваша суточная норма калорий:';
          if (currentW > 0 && targetW > 0 && currentW != targetW) {
            calorieLabel = targetW > currentW 
              ? 'Ваша суточная норма калорий с профицитом:' 
              : 'Ваша суточная норма калорий с дефицитом:';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Имя', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ageController, 
                        keyboardType: TextInputType.number, 
                        decoration: const InputDecoration(labelText: 'Возраст', border: OutlineInputBorder()),
                        onChanged: (_) => _calculateTarget(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _heightController, 
                        keyboardType: TextInputType.number, 
                        decoration: const InputDecoration(labelText: 'Рост (см)', border: OutlineInputBorder()),
                        onChanged: (_) => _calculateTarget(),
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
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Текущий вес (кг)', border: OutlineInputBorder()),
                        onChanged: (_) => _calculateTarget(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _targetWeightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Целевой вес (кг)', border: OutlineInputBorder()),
                        onChanged: (_) => _calculateTarget(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weeksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'За сколько недель достичь цели?', border: OutlineInputBorder()),
                  onChanged: (_) => _calculateTarget(),
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<double>(
                  key: ValueKey('activity_dropdown_${_activityFactor}'),
                  value: _activityFactor,
                  decoration: const InputDecoration(labelText: 'Уровень активности', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 1.2, child: Text('Сидячий (1.2)')),
                    DropdownMenuItem(value: 1.375, child: Text('Умеренный (1.375)')),
                    DropdownMenuItem(value: 1.55, child: Text('Средний (1.55)')),
                    DropdownMenuItem(value: 1.725, child: Text('Высокий (1.725)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _activityFactor = val;
                      _calculateTarget();
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    children: [
                      Text(calorieLabel, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '$_resultCalories ккал', 
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)
                      ),
                      if (_resultCalories == 1200)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            '⚠️ Установлен безопасный минимум!', 
                            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green),
                  child: const Text('Сохранить профиль и цель', style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}