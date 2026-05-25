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
  late UserProfile _profile;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double _selectedActivity = 1.375;

  final Map<double, String> _activityOptions = {
    1.2: 'Сидячий образ жизни (нет нагрузок)',
    1.375: 'Легкая активность (тренировки 1-3 раза в неделю)',
    1.55: 'Умеренная активность (тренировки 3-5 раз в неделю)',
    1.725: 'Высокая активность (тяжелый спорт каждый день)',
  };

  @override
  void initState() {
    super.initState();
    // Читаем профиль из локальной БД
    final rawProfile = _box.get('userProfile');
    _profile = UserProfile.fromMap(rawProfile);

    _nameController.text = _profile.fullName;
    _ageController.text = _profile.age.toString();
    _weightController.text = _profile.weight.toString();
    _heightController.text = _profile.height.toString();
    _selectedActivity = _profile.activityFactor;
  }

  void _saveProfile() {
    setState(() {
      _profile.fullName = _nameController.text;
      _profile.age = int.tryParse(_ageController.text) ?? 20;
      _profile.weight = double.tryParse(_weightController.text) ?? 100.0;
      _profile.height = double.tryParse(_heightController.text) ?? 175.0;
      _profile.activityFactor = _selectedActivity;
    });

    // Сохраняем в Hive на диск
    _box.put('userProfile', _profile.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль успешно сохранен!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка Профиля'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: SingleChildScrollView(
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
            DropdownButton<double>(
              value: _selectedActivity,
              isExpanded: true,
              items: _activityOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (val) => setState(() => _selectedActivity = val ?? 1.375),
            ),
            const Divider(height: 40, thickness: 2),
            Center(
              child: Column(
                children: [
                  Text('Рассчитанная норма:', style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                  Text('${_profile.dailyCalories} ккал/день', style: const TextStyle(color: Colors.green, fontSize: 32, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}