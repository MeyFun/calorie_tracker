import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart'; // Понадобится для красивого форматирования дат
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../models/food_group.dart';
import 'templates_screen.dart';
import '../models/food_template.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _box = Hive.box('settingsBox');
  
  // Текущая выбранная дата ( по дефолту — сегодня )
  DateTime _selectedDate = DateTime.now();
  
  // Дневник теперь хранит данные по дням: {'2026-05-25': [FoodGroup1, FoodGroup2]}
  Map<String, List<FoodGroup>> _allDaysJournal = {};
  List<FoodGroup> _currentDayEntries = [];

  // Контроллеры ввода
  final _groupNameController = TextEditingController(text: "Одиночный продукт");
  final _itemNameController = TextEditingController();
  final _baseWeightController = TextEditingController(text: "100");
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _eatenWeightController = TextEditingController();
  final _quantityController = TextEditingController(text: "1"); // Контроллер количества

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Преобразуем DateTime в строку-ключ "YYYY-MM-DD"
  String _dateToKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _loadData() {
    setState(() {
      // 1. Загружаем структуру журнала из базы
      var rawJournal = _box.get('foodJournalMap') as Map? ?? {};
      
      _allDaysJournal = rawJournal.map((key, value) {
        var list = value as List? ?? [];
        return MapEntry(
          key.toString(),
          list.map((e) => FoodGroup.fromMap(e as Map)).toList(),
        );
      });

      // 2. Достаем продукты конкретно для выбранного дня
      String dateKey = _dateToKey(_selectedDate);
      _currentDayEntries = _allDaysJournal[dateKey] ?? [];
    });
  }

  void _saveJournalToDatabase() {
    // Обновляем текущий день в общем словаре перед сохранением
    String dateKey = _dateToKey(_selectedDate);
    _allDaysJournal[dateKey] = _currentDayEntries;

    // Конвертируем всю структуру в Map для Hive
    final mapToSave = _allDaysJournal.map((key, value) {
      return MapEntry(key, value.map((g) => g.toMap()).toList());
    });

    _box.put('foodJournalMap', mapToSave);
  }

  double get _totalCaloriesToday => _currentDayEntries.fold(0, (sum, group) => sum + group.totalCalories);

  // Функция вызова календаря (Пункт 3)
  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025), // С какого года работает история
      lastDate: DateTime(2101),
      locale: const Locale('ru', 'RU'), // Локализация на русский язык
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green, // Цвет шапки календаря
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadData(); // Переподтягиваем продукты для новой выбранной даты
      });
    }
  }

  void _addFoodEntry() {
    if (_itemNameController.text.isEmpty || _eatenWeightController.text.isEmpty) return;

    final newItem = FoodItem(
      name: _itemNameController.text,
      protein: double.tryParse(_proteinController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      calories: double.tryParse(_calController.text) ?? 0,
      baseWeight: double.tryParse(_baseWeightController.text) ?? 100,
      weightEaten: double.tryParse(_eatenWeightController.text) ?? 0,
      quantity: int.tryParse(_quantityController.text) ?? 1, // Привязываем количество
    );

    setState(() {
      String gName = _groupNameController.text.trim();
      if (gName.isEmpty) gName = "Одиночный продукт";

      var existingGroup = _currentDayEntries.firstWhere(
        (g) => g.groupName.toLowerCase() == gName.toLowerCase(), 
        orElse: () => FoodGroup(groupName: gName, items: [])
      );

      if (!_currentDayEntries.contains(existingGroup)) {
        existingGroup.items.add(newItem);
        _currentDayEntries.add(existingGroup);
      } else {
        existingGroup.items.add(newItem);
      }

      _saveJournalToDatabase();
    });

    // Сброс полей
    _itemNameController.clear(); _calController.clear(); _proteinController.clear();
    _fatController.clear(); _carbsController.clear(); _eatenWeightController.clear();
    _baseWeightController.text = "100"; _groupNameController.text = "Одиночный продукт";
    _quantityController.text = "1"; // Сброс поля штучности
    
    Navigator.pop(context);
  }

  // Окно просмотра подробных данных КБЖУ с возможностью удаления
  void _showDetailsDialog(FoodGroup group) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Используем StatefulBuilder, чтобы окно обновлялось при удалении элементов
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Детали: ${group.groupName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: group.items.isEmpty
                  ? const Center(child: Text('В этом блюде не осталось продуктов.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: group.items.length,
                      itemBuilder: (context, idx) {
                        final item = group.items[idx];
                        return ExpansionTile(
                          // Выводим название, вес одной штуки и их количество
                          title: Text('${item.name} (${item.weightEaten.toStringAsFixed(0)}г х ${item.quantity}шт)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Итого вес: ${item.totalWeight.toStringAsFixed(0)}г | ${item.totalCalories.toStringAsFixed(0)} ккал'),
                          // КНОПКА УДАЛЕНИЯ ПРОДУКТА
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                // 1. Удаляем продукт из группы на главном экране
                                group.items.removeAt(idx);
                                
                                // 2. Если в группе не осталось продуктов, удаляем саму группу (блюдо)
                                if (group.items.isEmpty) {
                                  _currentDayEntries.remove(group);
                                  Navigator.pop(context); // Закрываем диалог, так как блюда больше нет
                                }
                                
                                // 3. Сохраняем обновленный журнал в локальную БД Hive
                                _saveJournalToDatabase();
                              });
                              
                              // Обновляем состояние внутри самого открытого диалогового окна
                              setDialogState(() {});
                            },
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Внесено в базу: КБЖУ на ${item.baseWeight.toStringAsFixed(0)}г'),
                                  const SizedBox(height: 4),
                                  // --- Считаем и выводим КБЖУ строго на 100 грамм для наглядности ---
                                  Text(
                                    '• На 100г продукта:', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])
                                  ),
                                  Text('  Калории: ${((item.calories * 100) / item.baseWeight).toStringAsFixed(1)} ккал'),
                                  Text(
                                    '  Б: ${((item.protein * 100) / item.baseWeight).toStringAsFixed(1)}г | '
                                    'Ж: ${((item.fat * 100) / item.baseWeight).toStringAsFixed(1)}г | '
                                    'У: ${((item.carbs * 100) / item.baseWeight).toStringAsFixed(1)}г'
                                  ),
                                  const Divider(),
                                  // Фактически съеденное (остается без изменений, так как считает сумму)
                                  Text(
                                    'Фактически усвоено (на ${item.totalWeight.toStringAsFixed(0)}г):', 
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                                  ),
                                  Text('• Расчетные Белки: ${item.totalProtein.toStringAsFixed(1)}г'),
                                  Text('• Расчетные Жиры: ${item.totalFat.toStringAsFixed(1)}г'),
                                  Text('• Расчетные Углеводы: ${item.totalCarbs.toStringAsFixed(1)}г'),
                                ],
                              ),
                            )
                          ],
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Закрыть')
              )
            ],
          );
        },
      ),
    );
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
              const Text('Добавить пищу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // --- КНОПКА ВЫБОРА ИЗ БАЗЫ ГОТОВЫХ ПРОДУКТОВ ---
              OutlinedButton.icon(
                onPressed: () async {
                  // Открываем мини-окно выбора шаблона прямо поверх формы
                  final templateBox = Hive.box('templatesBox');
                  final List rawTemplates = templateBox.get('list') as List? ?? [];
                  final templates = rawTemplates.map((e) => FoodTemplate.fromMap(e as Map)).toList();

                  if (templates.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ваша база продуктов пуста! Сначала добавьте продукты через верхнее меню.')),
                    );
                    return;
                  }

                  // Показываем быстрый диалог выбора
                  final FoodTemplate? selected = await showDialog<FoodTemplate>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Выбрать продукт из базы'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: templates.length,
                          itemBuilder: (context, idx) {
                            final t = templates[idx];
                            return ListTile(
                              title: Text(t.name),
                              subtitle: Text('${t.calories.toStringAsFixed(0)} ккал на ${t.baseWeight.toStringAsFixed(0)}г'),
                              onTap: () => Navigator.pop(context, t),
                            );
                          },
                        ),
                      ),
                    ),
                  );

                  // Если пользователь выбрал продукт, автоматически заполняем поля формы!
                  if (selected != null) {
                    _itemNameController.text = selected.name;
                    _baseWeightController.text = selected.baseWeight.toStringAsFixed(0);
                    _calController.text = selected.calories.toStringAsFixed(0);
                    _proteinController.text = selected.protein.toString();
                    _fatController.text = selected.fat.toString();
                    _carbsController.text = selected.carbs.toString();
                  }
                },
                icon: const Icon(Icons.storage, color: Colors.green),
                label: const Text('Выбрать из базы продуктов', style: TextStyle(color: Colors.green)),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
              ),
              
              const SizedBox(height: 12),
              TextField(controller: _groupNameController, decoration: const InputDecoration(labelText: 'Название группы/блюда', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _itemNameController, decoration: const InputDecoration(labelText: 'Конкретный ингредиент', border: OutlineInputBorder())),
              Row(
                children: [
                  Expanded(child: TextField(controller: _baseWeightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вес на упаковке (г)'))),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _eatenWeightController, 
                      keyboardType: TextInputType.number, 
                      decoration: const InputDecoration(labelText: 'Вес 1 порции/шт (г)', border: OutlineInputBorder())
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _quantityController, 
                      keyboardType: TextInputType.number, 
                      decoration: const InputDecoration(labelText: 'Кол-во (шт)', border: OutlineInputBorder())
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addFoodEntry,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green),
                child: const Text('Внести в дневник', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    // Красиво форматируем выбранную дату для вывода на экран (например, "25 мая")
    String formattedDate = DateFormat('d MMMM', 'ru').format(_selectedDate);
    
    // Проверка, выбран ли сегодняшний день
    bool isToday = _dateToKey(_selectedDate) == _dateToKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Дневник: Сегодня' : 'Дневник: $formattedDate'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.book_online_outlined),
            tooltip: 'База продуктов',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TemplatesScreen()),
              );
            },
          ),
          // Кнопка вызова календаря
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Выбрать дату',
            onPressed: () => _selectDate(context),
          )
        ],
      ),
      body: Column(
        children: [
          ValueListenableBuilder(
            valueListenable: Hive.box('settingsBox').listenable(),
            builder: (context, Box box, child) {
              final rawProfile = box.get('userProfile');
              final profile = UserProfile.fromMap(rawProfile);
              final int norm = profile.dailyCalories;

              // Считаем съеденные БЖУ за сегодня
              double eatenP = _currentDayEntries.fold(0, (sum, g) => sum + g.totalProtein);
              double eatenF = _currentDayEntries.fold(0, (sum, g) => sum + g.totalFat);
              double eatenC = _currentDayEntries.fold(0, (sum, g) => sum + g.totalCarbs);

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Text('Норма дня: $norm ккал', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: norm > 0 ? _totalCaloriesToday / norm : 0,
                      backgroundColor: Colors.grey[200],
                      color: _totalCaloriesToday > norm ? Colors.red : Colors.green,
                      minHeight: 12,
                    ),
                    const SizedBox(height: 8),
                    Text('Принято за $formattedDate: ${_totalCaloriesToday.toStringAsFixed(0)} / $norm ккал', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    
                    const Divider(height: 24, thickness: 1),
                    
                    // --- СТАТИСТИКА БЖУ ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutrientColumn('Белки', eatenP, profile.targetProtein, Colors.orange),
                        _buildNutrientColumn('Жиры', eatenF, profile.targetFat, Colors.blue),
                        _buildNutrientColumn('Угл.', eatenC, profile.targetCarbs, Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: _currentDayEntries.isEmpty
                ? Center(
                    child: Text(
                      isToday 
                        ? 'Сегодня вы еще ничего не добавили.' 
                        : 'Нет записей за $formattedDate.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _currentDayEntries.length,
                    itemBuilder: (context, index) {
                      final group = _currentDayEntries[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          onTap: () => _showDetailsDialog(group),
                          title: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text('Ингредиентов: ${group.items.length}\nБ: ${group.totalProtein.toStringAsFixed(1)} | Ж: ${group.totalFat.toStringAsFixed(1)} | У: ${group.totalCarbs.toStringAsFixed(1)}'),
                          trailing: Text('${group.totalCalories.toStringAsFixed(0)} ккал', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                          isThreeLine: true,
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

  // Вспомогательный виджет для красивого вывода отдельного нутриента
  Widget _buildNutrientColumn(String label, double eaten, int target, Color color) {
    double progress = target > 0 ? eaten / target : 0;
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text('${eaten.toStringAsFixed(0)}/${target}г', style: TextStyle(color: Colors.grey[800], fontSize: 13)),
        const SizedBox(height: 6),
        SizedBox(
          width: 70,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: progress > 1.0 ? Colors.red : color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}