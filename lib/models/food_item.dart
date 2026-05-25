class FoodItem {
  String name;
  double protein;
  double fat;
  double carbs;
  double calories;
  double baseWeight;  // На сколько грамм (например, 100г или 1000г)
  double weightEaten; // Вес ОДНОЙ штуки / порции
  int quantity;       // КОЛИЧЕСТВО штук (Новое поле)

  FoodItem({
    required this.name,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.baseWeight,
    required this.weightEaten,
    this.quantity = 1, // По умолчанию 1 штука
  });

  // Общий фактический вес с учетом количества
  double get totalWeight => weightEaten * quantity;

  // Расчет КБЖУ на суммарный съеденный вес всех штук
  double get totalCalories => (calories * totalWeight) / baseWeight;
  double get totalProtein => (protein * totalWeight) / baseWeight;
  double get totalFat => (fat * totalWeight) / baseWeight;
  double get totalCarbs => (carbs * totalWeight) / baseWeight;

  Map<String, dynamic> toMap() => {
    'name': name,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
    'calories': calories,
    'baseWeight': baseWeight,
    'weightEaten': weightEaten,
    'quantity': quantity,
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
      quantity: map['quantity'] ?? 1,
    );
  }
}