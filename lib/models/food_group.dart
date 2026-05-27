import 'food_item.dart';

class FoodGroup {
  String groupName;
  List<FoodItem> items;
  double portionRatio;

  FoodGroup({
    required this.groupName,
    required this.items,
    this.portionRatio = 1.0,
  });

  // Общие КБЖУ группы считаются автоматически на основе всех входящих в нее продуктов
  double get totalCalories => items.fold(0.0, (sum, item) => sum + item.totalCalories) * portionRatio;
  double get totalProtein => items.fold(0.0, (sum, item) => sum + item.totalProtein) * portionRatio;
  double get totalFat => items.fold(0.0, (sum, item) => sum + item.totalFat) * portionRatio;
  double get totalCarbs => items.fold(0.0, (sum, item) => sum + item.totalCarbs) * portionRatio;

  Map<String, dynamic> toMap() => {
    'groupName': groupName,
    'items': items.map((e) => e.toMap()).toList(),
    'portionRatio': portionRatio,
  };

  factory FoodGroup.fromMap(Map<dynamic, dynamic> map) {
    var itemsList = map['items'] as List? ?? [];
    return FoodGroup(
      groupName: map['groupName'] ?? '',
      items: itemsList.map((e) => FoodItem.fromMap(e as Map)).toList(),
      portionRatio: (map['portionRatio'] as num?)?.toDouble() ?? 1.0,
    );
  }
}