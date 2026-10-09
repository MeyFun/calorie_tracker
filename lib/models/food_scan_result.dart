class FoodScanResult {
  final String dishName;
  final List<String> ingredients;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbsPer100g;
  final double estimatedWeightGrams;

  const FoodScanResult({
    required this.dishName,
    required this.ingredients,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbsPer100g,
    required this.estimatedWeightGrams,
  });

  factory FoodScanResult.fromJson(Map<String, dynamic> json) {
    final dishName = json['dish_name'];
    final rawIngredients = json['ingredients'];
    if (dishName is! String ||
        dishName.trim().isEmpty ||
        rawIngredients is! List) {
      throw const FormatException(
        'Gemini вернул неполное описание блюда или ингредиентов.',
      );
    }

    final ingredients = rawIngredients
        .whereType<String>()
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .toList();
    if (ingredients.isEmpty) {
      throw const FormatException('Не удалось определить ингредиенты блюда.');
    }

    final calories = _readNonNegativeNumber(json, 'calories_per_100g');
    final protein = _readNonNegativeNumber(json, 'protein_per_100g');
    final fat = _readNonNegativeNumber(json, 'fat_per_100g');
    final carbs = _readNonNegativeNumber(json, 'carbs_per_100g');
    final weight = _readNonNegativeNumber(json, 'estimated_weight_g');
    if (weight <= 0) {
      throw const FormatException('Не удалось оценить вес порции.');
    }

    return FoodScanResult(
      dishName: dishName.trim(),
      ingredients: ingredients,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      fatPer100g: fat,
      carbsPer100g: carbs,
      estimatedWeightGrams: weight,
    );
  }

  static double _readNonNegativeNumber(Map<String, dynamic> json, String key) {
    final value = json[key];
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      throw FormatException('Gemini вернул некорректное значение "$key".');
    }
    return parsed;
  }
}
