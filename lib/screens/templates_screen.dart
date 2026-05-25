import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/food_template.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _templateBox = Hive.box('templatesBox');
  
  final _nameController = TextEditingController();
  final _baseWeightController = TextEditingController(text: "100");
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();

  List<FoodTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() {
    final rawData = _templateBox.get('list') as List? ?? [];
    setState(() {
      _templates = rawData.map((e) => FoodTemplate.fromMap(e as Map)).toList();
    });
  }

  void _saveTemplates() {
    final mapList = _templates.map((t) => t.toMap()).toList();
    _templateBox.put('list', mapList);
  }

  void _addTemplate() {
    if (_nameController.text.isEmpty || _calController.text.isEmpty) return;

    final newTemplate = FoodTemplate(
      name: _nameController.text,
      protein: double.tryParse(_proteinController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      calories: double.tryParse(_calController.text) ?? 0,
      baseWeight: double.tryParse(_baseWeightController.text) ?? 100,
    );

    setState(() {
      _templates.add(newTemplate);
      _saveTemplates();
    });

    _nameController.clear(); _calController.clear(); _proteinController.clear();
    _fatController.clear(); _carbsController.clear();
    _baseWeightController.text = "100";
    
    Navigator.pop(context);
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Новый продукт в базу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Название (напр. Куриное филе сырое)', border: OutlineInputBorder())),
              Row(
                children: [
                  Expanded(child: TextField(controller: _baseWeightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Вес базы (г)'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _calController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Калории базы'))),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTemplate,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.green),
                child: const Text('Сохранить в базу', style: TextStyle(color: Colors.white)),
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
      appBar: AppBar(title: const Text('База продуктов'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: _templates.isEmpty
          ? const Center(child: Text('База пуста. Добавьте свои частые продукты!', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, idx) {
                final t = _templates[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('На ${t.baseWeight.toStringAsFixed(0)}г: Б: ${t.protein} | Ж: ${t.fat} | У: ${t.carbs}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${t.calories.toStringAsFixed(0)} ккал', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _templates.removeAt(idx);
                              _saveTemplates();
                            });
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}