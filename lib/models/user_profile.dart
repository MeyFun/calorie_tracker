class UserProfile {
  String fullName;
  int age;
  double weight;
  double height;
  double activityFactor;

  UserProfile({
    this.fullName = '',
    this.age = 20,
    this.weight = 100.0,
    this.height = 175.0,
    this.activityFactor = 1.375,
  });

  // Формула Миффлина-Сан Жеора для калорий
  int get dailyCalories {
    if (weight == 0 || height == 0 || age == 0) return 2500;
    return (((10 * weight) + (6.25 * height) - (5 * age) + 5) * activityFactor).round();
  }

  // --- РАСЧЕТ НОРМЫ ГРАММОВ БЖУ ---
  
  // Белки: 2г на кг веса
  int get targetProtein => (weight * 2.0).round();

  // Жиры: 0.9г на кг веса
  int get targetFat => (weight * 0.9).round();

  // Углеводы: остаток калорий делим на 4 ккал
  int get targetCarbs {
    int proteinCalories = targetProtein * 4;
    int fatCalories = targetFat * 9;
    int remainingCalories = dailyCalories - (proteinCalories + fatCalories);
    return remainingCalories > 0 ? (remainingCalories / 4).round() : 100;
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'age': age,
    'weight': weight,
    'height': height,
    'activityFactor': activityFactor,
  };

  factory UserProfile.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return UserProfile();
    return UserProfile(
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? 20,
      weight: (map['weight'] as num?)?.toDouble() ?? 100.0,
      height: (map['height'] as num?)?.toDouble() ?? 175.0,
      activityFactor: (map['activityFactor'] as num?)?.toDouble() ?? 1.375,
    );
  }
}