class FoodTemplate {
  String name;
  double protein;
  double fat;
  double carbs;
  double calories;
  double baseWeight; // Обычно 100г

  FoodTemplate({
    required this.name,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.baseWeight,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'calories': calories,
    'baseWeight': baseWeight,
  };

  factory FoodTemplate.fromMap(Map<dynamic, dynamic> map) {
    return FoodTemplate(
      name: map['name'] ?? '',
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      baseWeight: (map['baseWeight'] as num?)?.toDouble() ?? 100.0,
    );
  }
}