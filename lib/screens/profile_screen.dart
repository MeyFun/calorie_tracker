import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _box = Hive.box('settingsBox');

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double _selectedActivity = 1.375;

  // Флаг, чтобы не сбрасывать курсор у пользователя во время ввода
  bool _isInitialized = false;

  final Map<double, String> _activityOptions = {
    1.2: 'Сидячий образ жизни (нет нагрузок)',
    1.375: 'Легкая активность (тренировки 1-3 раза в неделю)',
    1.55: 'Умеренная активность (тренировки 3-5 раз в неделю)',
    1.725: 'Высокая активность (тяжелый спорт каждый день)',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // Метод синхронизации текста в контроллерах с тем, что реально лежит в Hive
  void _initFieldsWithData(UserProfile profile) {
    _nameController.text = profile.fullName;
    _ageController.text = profile.age.toString();
    _weightController.text = profile.weight.toStringAsFixed(1);
    _heightController.text = profile.height.toStringAsFixed(0);
    _selectedActivity = profile.activityFactor;
    _isInitialized = true;
  }

  void _saveProfile() {
    // Читаем самую свежую актуальную модель из базы (со всеми targetWeight и weeksToGoal из настроек)
    final rawProfile = _box.get('userProfile');
    final currentProfile = UserProfile.fromMap(rawProfile as Map?);

    // Модифицируем только те поля, за которые отвечает ЭТОТ экран
    currentProfile.fullName = _nameController.text;
    currentProfile.age = int.tryParse(_ageController.text) ?? 20;
    currentProfile.weight = double.tryParse(_weightController.text) ?? 100.0;
    currentProfile.height = double.tryParse(_heightController.text) ?? 175.0;
    currentProfile.activityFactor = _selectedActivity;

    // Сохраняем обратно на диск цельную обновленную структуру
    _box.put('userProfile', currentProfile.toMap());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль успешно сохранен!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка Профиля'), 
        backgroundColor: Colors.green, 
        foregroundColor: Colors.white
      ),
      // Оборачиваем ВЕСЬ body в прослушивание Hive-коробки
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(keys: ['userProfile']),
        builder: (context, Box box, child) {
          final raw = box.get('userProfile');
          final liveProfile = UserProfile.fromMap(raw as Map?);

          // Если зашли первый раз ИЛИ данные в базе изменились извне (из SettingsScreen)
          if (!_isInitialized || _hasExternalChanges(liveProfile)) {
            _initFieldsWithData(liveProfile);
          }

          // Определяем тип цели для отображения надписи
          String goalText = 'Норма поддержания веса:';
          if (liveProfile.weeksToGoal > 0) {
            if (liveProfile.targetWeight < liveProfile.weight) {
              goalText = 'Рассчитанная норма (Дефицит):';
            } else if (liveProfile.targetWeight > liveProfile.weight) {
              goalText = 'Рассчитанная норма (Профицит):';
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ФИО', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Возраст', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Рост (см)', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вес (кг)', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Уровень физической активности:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<double>(
                  key: ValueKey('profile_activity_dropdown_${_selectedActivity}'),
                  value: _selectedActivity,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: _activityOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedActivity = val;
                        _isInitialized = false; // Позволяем перерисовать состояние дропдауна
                      });
                    }
                  },
                ),
                const Divider(height: 40, thickness: 2),
                Center(
                  child: Column(
                    children: [
                      Text(
                        goalText, 
                        style: TextStyle(color: Colors.grey[700], fontSize: 16)
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${liveProfile.dailyCalories} ккал/день', 
                        style: const TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(55), backgroundColor: Colors.green),
                  child: const Text('Сохранить изменения', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Проверка: изменился ли вес/данные в базе извне (например, на экране настроек цели), 
  // пока открыт этот экран
  bool _hasExternalChanges(UserProfile liveProfile) {
    final currentInputWeight = double.tryParse(_weightController.text) ?? 0.0;
    final currentInputHeight = double.tryParse(_heightController.text) ?? 0.0;
    final currentInputAge = int.tryParse(_ageController.text) ?? 0;
    final currentInputName = _nameController.text;

    return (liveProfile.weight - currentInputWeight).abs() > 0.09 ||
           (liveProfile.height - currentInputHeight).abs() > 0.09 ||
           liveProfile.age != currentInputAge ||
           liveProfile.fullName != currentInputName;
  }
}