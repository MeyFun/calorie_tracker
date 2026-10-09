import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/food_template.dart';
import '../services/product_catalog_service.dart';
import '../widgets/health_glass.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _templateBox = Hive.box('templatesBox');
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _baseWeightController = TextEditingController(text: '100');
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _catalogService = ProductCatalogService();

  List<FoodTemplate> _templates = [];
  List<CatalogProduct> _catalog = [];
  String _searchQuery = '';
  String? _catalogError;
  bool _isCatalogLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _baseWeightController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    super.dispose();
  }

  void _loadTemplates() {
    final rawData = _templateBox.get('list') as List? ?? [];
    setState(() {
      _templates = rawData.map((e) => FoodTemplate.fromMap(e as Map)).toList();
    });
  }

  void _saveTemplates() {
    _templateBox.put('list', _templates.map((t) => t.toMap()).toList());
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isCatalogLoading = true;
      _catalogError = null;
    });
    try {
      final catalog = await _catalogService.loadCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _isCatalogLoading = false;
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogError = 'Не удалось прочитать каталог: $error';
        _isCatalogLoading = false;
      });
    } on FlutterError catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogError = 'Не удалось загрузить каталог: $error';
        _isCatalogLoading = false;
      });
    }
  }

  void _addCatalogProduct(FoodTemplate product) {
    final normalizedName = product.name.trim().toLowerCase();
    if (_templates.any(
      (template) => template.name.trim().toLowerCase() == normalizedName,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот продукт уже есть в вашей базе.')),
      );
      return;
    }

    setState(() {
      _templates.add(product);
      _saveTemplates();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Продукт добавлен в вашу базу.')),
    );
  }

  void _resetForm() {
    _nameController.clear();
    _baseWeightController.text = '100';
    _calController.clear();
    _proteinController.clear();
    _fatController.clear();
    _carbsController.clear();
  }

  void _showTemplateEditor({FoodTemplate? template, int? index}) {
    _nameController.text = template?.name ?? '';
    _baseWeightController.text = template?.baseWeight.toString() ?? '100';
    _calController.text = template?.calories.toString() ?? '';
    _proteinController.text = template?.protein.toString() ?? '';
    _fatController.text = template?.fat.toString() ?? '';
    _carbsController.text = template?.carbs.toString() ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template == null
                      ? 'Новый продукт в базу'
                      : 'Редактировать продукт',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название продукта',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _baseWeightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Вес базы (г)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _calController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Калории'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _proteinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Белки'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Жиры'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _carbsController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Углеводы',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final baseWeight = _parseNumber(_baseWeightController.text);
                    final calories = _parseNumber(_calController.text);
                    final protein = _parseNumber(_proteinController.text) ?? 0;
                    final fat = _parseNumber(_fatController.text) ?? 0;
                    final carbs = _parseNumber(_carbsController.text) ?? 0;

                    if (_nameController.text.trim().isEmpty ||
                        baseWeight == null ||
                        baseWeight <= 0 ||
                        calories == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Укажите название, вес базы и калории.',
                          ),
                        ),
                      );
                      return;
                    }

                    final updatedTemplate = FoodTemplate(
                      name: _nameController.text.trim(),
                      baseWeight: baseWeight,
                      calories: calories,
                      protein: protein,
                      fat: fat,
                      carbs: carbs,
                    );

                    setState(() {
                      if (index == null) {
                        _templates.add(updatedTemplate);
                      } else {
                        _templates[index] = updatedTemplate;
                      }
                      _saveTemplates();
                    });
                    Navigator.pop(sheetContext);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: const Color(0xFF6D9B7E),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    template == null
                        ? 'Сохранить в базу'
                        : 'Сохранить изменения',
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(_resetForm);
  }

  double? _parseNumber(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : null;
  }

  void _deleteTemplate(int index) {
    setState(() {
      _templates.removeAt(index);
      _saveTemplates();
    });
  }

  Widget _buildTemplateTile(
    FoodTemplate template, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final baseWeight = template.baseWeight > 0 ? template.baseWeight : 100;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        onTap: onTap,
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'На 100г: Б ${((template.protein * 100) / baseWeight).toStringAsFixed(1)}г | '
          'Ж ${((template.fat * 100) / baseWeight).toStringAsFixed(1)}г | '
          'У ${((template.carbs * 100) / baseWeight).toStringAsFixed(1)}г',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing:
            trailing ??
            Text(
              '${((template.calories * 100) / baseWeight).toStringAsFixed(0)} ккал/100г',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6D9B7E),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogResults = _catalogService.search(_catalog, _searchQuery);
    return Scaffold(
      appBar: AppBar(
        title: const Text('База продуктов'),
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Colors.transparent,
      body: HealthBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (query) => setState(() => _searchQuery = query),
                decoration: const InputDecoration(
                  labelText: 'Найти продукт в офлайн-каталоге',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            if (_isCatalogLoading)
              const LinearProgressIndicator()
            else if (_catalogError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _catalogError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCatalog,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  if (!_isCatalogLoading && _catalogError == null) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text('Каталог USDA — значения на 100 г'),
                    ),
                    for (final product in catalogResults)
                      _buildTemplateTile(
                        product.template,
                        onTap: () => _addCatalogProduct(product.template),
                        trailing: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF6D9B7E),
                        ),
                      ),
                    if (catalogResults.isEmpty &&
                        _searchQuery.trim().isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Подходящие продукты не найдены.'),
                      ),
                  ],
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Моя база — нажмите на продукт для редактирования',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_templates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Личная база пуста. Добавьте продукт из каталога или создайте его вручную.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    for (var index = 0; index < _templates.length; index++)
                      Dismissible(
                        key: ValueKey('${_templates[index].name}_$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteTemplate(index),
                        child: _buildTemplateTile(
                          _templates[index],
                          onTap: () => _showTemplateEditor(
                            template: _templates[index],
                            index: index,
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                _showTemplateEditor(
                                  template: _templates[index],
                                  index: index,
                                );
                              } else if (action == 'delete') {
                                _deleteTemplate(index);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Редактировать'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Удалить'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Источник справочных значений: USDA FoodData Central, SR Legacy. '
                      'КБЖУ могут отличаться для конкретного продукта.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateEditor(),
        backgroundColor: const Color(0xFF6D9B7E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
