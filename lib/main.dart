import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const CalorieTrackerApp());
}

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мой Калькулятор Калорий',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

// --- МОДЕЛИ ДАННЫХ ---
class UserProfile {
  double weight;
  double height;
  int age;
  double activityFactor; // Например, 1.375 для тренировок 3 раза в неделю

  UserProfile({
    required this.weight,
    required this.height,
    required this.age,
    required this.activityFactor,
  });

  // Формула Миффлина-Сан Жеора для мужчин
  double get dailyCalories {
    return ((10 * weight) + (6.25 * height) - (5 * age) + 5) * activityFactor;
  }
}

class FoodItem {
  String name;
  double protein;
  double fat;
  double carbs;
  double calories;
  double baseWeight; // На сколько грамм указано на упаковке (100 или 1000)
  double weightEaten; // Сколько реально добавили в блюдо

  FoodItem({
    required this.name,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.baseWeight,
    required this.weightEaten,
  });

  // Геттеры для расчета фактических КБЖУ на съеденный вес
  double get totalCalories => (calories * weightEaten) / baseWeight;
  double get totalProtein => (protein * weightEaten) / baseWeight;
  double get totalFat => (fat * weightEaten) / baseWeight;
  double get totalCarbs => (carbs * weightEaten) / baseWeight;
}

// --- ЭКРАНЫ ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Дефолтный профиль (можно менять)
  final UserProfile _profile = UserProfile(weight: 146, height: 185, age: 20, activityFactor: 1.375);
  final List<FoodItem> _eatenFoods = [];

  // Контроллеры для ввода нового продукта
  final _nameController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _calController = TextEditingController();
  final _baseWeightController = TextEditingController(text: "100"); // по дефолту 100г
  final _eatenWeightController = TextEditingController();

  double get _totalEatenCalories => _eatenFoods.fold(0, (sum, item) => sum + item.totalCalories);

  void _addFoodItem() {
    if (_nameController.text.isEmpty || _eatenWeightController.text.isEmpty) return;

    setState(() {
      _eatenFoods.add(
        FoodItem(
          name: _nameController.text,
          protein: double.tryParse(_proteinController.text) ?? 0,
          fat: double.tryParse(_fatController.text) ?? 0,
          carbs: double.tryParse(_carbsController.text) ?? 0,
          calories: double.tryParse(_calController.text) ?? 0,
          baseWeight: double.tryParse(_baseWeightController.text) ?? 100,
          weightEaten: double.tryParse(_eatenWeightController.text) ?? 0,
        ),
      );
    });

    // Очищаем поля после добавления
    _nameController.clear();
    _proteinController.clear();
    _fatController.clear();
    _carbsController.clear();
    _calController.clear();
    _baseWeightController.text = "100";
    _eatenWeightController.clear();
    Navigator.pop(context);
  }

  void _showAddFoodBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Добавить продукт', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Название продукта (например, Индейка)')),
              Row(
                children: [
                  Expanded(child: TextField(controller: _baseWeightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Базовый вес (г)'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Калории на этот вес'))),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextField(controller: _proteinController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Белки'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _fatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Жиры'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _carbsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Углеводы'))),
                ],
              ),
              TextField(controller: _eatenWeightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Сколько грамм добавлено в блюдо?')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addFoodItem,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green),
                child: const Text('Добавить в дневник', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор КБЖУ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Виджет прогресса калорий
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)]),
            child: Column(
              children: [
                Text('Норма дня: ${_profile.dailyCalories.toStringAsFixed(0)} ккал', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: _totalEatenCalories / _profile.dailyCalories,
                  backgroundColor: Colors.grey[300],
                  color: _totalEatenCalories > _profile.dailyCalories ? Colors.red : Colors.green,
                  minHeight: 12,
                ),
                const SizedBox(height: 10),
                Text('Съедено: ${_totalEatenCalories.toStringAsFixed(1)} / ${_profile.dailyCalories.toStringAsFixed(0)} ккал', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const Text('Съеденные продукты:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          // Список съеденного
          Expanded(
            child: _eatenFoods.isEmpty
                ? const Center(child: Text('Вы пока ничего не добавили. Нажмите +'))
                : ListView.builder(
                    itemCount: _eatenFoods.length,
                    itemBuilder: (context, index) {
                      final item = _eatenFoods[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text('${item.name} (${item.weightEaten.toStringAsFixed(0)}г)'),
                          subtitle: Text('Б: ${item.totalProtein.toStringAsFixed(1)} | Ж: ${item.totalFat.toStringAsFixed(1)} | У: ${item.totalCarbs.toStringAsFixed(1)}'),
                          trailing: Text('${item.totalCalories.toStringAsFixed(0)} ккал', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodBottomSheet,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}