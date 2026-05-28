class UserProfile {
  String fullName;
  int age;
  double weight;          // Текущий вес
  double targetWeight;    // Целевой вес
  int weeksToGoal;        // Срок в неделях
  double height;
  double activityFactor;

  UserProfile({
    this.fullName = '',
    this.age = 20,
    this.weight = 100.0,
    this.targetWeight = 80.0, // Дефолтное значение
    this.weeksToGoal = 10,    // Дефолтное значение
    this.height = 175.0,
    this.activityFactor = 1.375,
  });

  // 1. Считаем чистую норму поддержания текущего веса
  int get maintenanceCalories {
  double bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
  return (bmr * activityFactor).round();
}

  // 2. Модифицированный геттер: рассчитывает норму уже с учетом дефицита для похудения
  int get dailyCalories {
  int maintenance = maintenanceCalories;

  // Если цель не задана или срок равен нулю — возвращаем просто поддержание
  if (weeksToGoal <= 0 || targetWeight == weight) {
    return maintenance;
  }

  // Считаем общую разницу в весе
  double weightDelta = targetWeight - weight; // Положительное при наборе, отрицательное при похудении

  // Переводим разницу в калории (примерно 7700 ккал на 1 кг жира/массы)
  // Делим на количество дней (weeksToGoal * 7)
  double caloriesDeltaPerDay = (weightDelta * 7700) / (weeksToGoal * 7);

  int result = maintenance + caloriesDeltaPerDay.round();

  return result;
}

  // --- РАСЧЕТ НОРМЫ ГРАММОВ БЖУ (подстраивается под dailyCalories) ---
  
  // Белки: 2г на кг текущего веса
  int get targetProtein => (weight * 2.0).round();

  // Жиры: 0.9г на кг текущего веса
  int get targetFat => (weight * 0.9).round();

  // Углеводы: остаток от урезанных калорий делим на 4 ккал
  int get targetCarbs {
    int proteinCalories = targetProtein * 4;
    int fatCalories = targetFat * 9;
    int remainingCalories = dailyCalories - (proteinCalories + fatCalories);
    
    // Если из-за жесткого дефицита на углеводы не остается калорий,
    // возвращаем минимальный порог (например, 50г), чтобы не уйти в ноль
    return remainingCalories > 0 ? (remainingCalories / 4).round() : 50;
  }

  // --- СЕРИАЛИЗАЦИЯ ДЛЯ HIVE ---

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'age': age,
    'weight': weight,
    'targetWeight': targetWeight,
    'weeksToGoal': weeksToGoal,
    'height': height,
    'activityFactor': activityFactor,
  };

  factory UserProfile.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return UserProfile();
    return UserProfile(
      fullName: map['fullName'] ?? '',
      age: map['age'] ?? 20,
      weight: (map['weight'] as num?)?.toDouble() ?? 100.0,
      targetWeight: (map['targetWeight'] as num?)?.toDouble() ?? 80.0,
      weeksToGoal: map['weeksToGoal'] ?? 10,
      height: (map['height'] as num?)?.toDouble() ?? 175.0,
      activityFactor: (map['activityFactor'] as num?)?.toDouble() ?? 1.375,
    );
  }
}