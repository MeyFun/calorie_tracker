class FoodItem {
  String name;
  double protein;
  double fat;
  double carbs;
  double calories;
  double baseWeight;  // На сколько грамм (например 100г или 1000г)
  double weightEaten; // Сколько фактически съедено / добавлено в блюдо

  FoodItem({
    required this.name,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.baseWeight,
    required this.weightEaten,
  });

  // Расчет КБЖУ на съеденную массу
  double get totalCalories => (calories * weightEaten) / baseWeight;
  double get totalProtein => (protein * weightEaten) / baseWeight;
  double get totalFat => (fat * weightEaten) / baseWeight;
  double get totalCarbs => (carbs * weightEaten) / baseWeight;

  Map<String, dynamic> toMap() => {
    'name': name,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'calories': calories,
    'baseWeight': baseWeight,
    'weightEaten': weightEaten,
  };

  factory FoodItem.fromMap(Map<dynamic, dynamic> map) {
    return FoodItem(
      name: map['name'] ?? '',
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      baseWeight: (map['baseWeight'] as num?)?.toDouble() ?? 100.0,
      weightEaten: (map['weightEaten'] as num?)?.toDouble() ?? 0.0,
    );
  }
}