import 'food_item.dart';

class FoodGroup {
  String groupName;
  List<FoodItem> items;

  FoodGroup({
    required this.groupName,
    required this.items,
  });

  // Общие КБЖУ группы считаются автоматически на основе всех входящих в нее продуктов
  double get totalCalories => items.fold(0, (sum, item) => sum + item.totalCalories);
  double get totalProtein => items.fold(0, (sum, item) => sum + item.totalProtein);
  double get totalFat => items.fold(0, (sum, item) => sum + item.totalFat);
  double get totalCarbs => items.fold(0, (sum, item) => sum + item.totalCarbs);

  Map<String, dynamic> toMap() => {
    'groupName': groupName,
    'items': items.map((e) => e.toMap()).toList(),
  };

  factory FoodGroup.fromMap(Map<dynamic, dynamic> map) {
    var itemsList = map['items'] as List? ?? [];
    return FoodGroup(
      groupName: map['groupName'] ?? '',
      items: itemsList.map((e) => FoodItem.fromMap(e as Map)).toList(),
    );
  }
}