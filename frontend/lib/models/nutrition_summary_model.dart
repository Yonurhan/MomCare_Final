class NutritionSummary {
  final Goal goals;
  final Consumed consumed;

  NutritionSummary({
    required this.goals,
    required this.consumed,
  });

  factory NutritionSummary.fromJson(Map<String, dynamic> json) {
    return NutritionSummary(
      goals: Goal.fromJson(json['goal'] ?? {}),
      consumed: Consumed.fromJson(json['consumed'] ?? {}),
    );
  }
}

class Goal {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final int waterMl;
  final double sleepHours;

  Goal({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.waterMl,
    required this.sleepHours,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      calories: (json['calories'] as num? ?? 0).toDouble(),
      protein: (json['protein'] as num? ?? 0).toDouble(),
      fat: (json['fat'] as num? ?? 0).toDouble(),
      carbs: (json['carbs'] as num? ?? 0).toDouble(),
      waterMl: (json['water_ml'] as num? ?? 2000).toInt(), // Static goal
      sleepHours: (json['sleep_hours'] as num? ?? 8.0).toDouble(), // Static goal
    );
  }
}

class Consumed {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final int water;
  final double sleep;

  Consumed({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.water,
    required this.sleep,
  });

  factory Consumed.fromJson(Map<String, dynamic> json) {
    // The keys here match the response from your backend's DailyNutritionLog model
    return Consumed(
      calories: (json['daily_calories'] as num? ?? 0).toDouble(),
      protein: (json['daily_protein'] as num? ?? 0).toDouble(),
      fat: (json['daily_fat'] as num? ?? 0).toDouble(),
      carbs: (json['daily_carbs'] as num? ?? 0).toDouble(),
      water: (json['daily_water'] as num? ?? 0).toInt(),
      sleep: (json['daily_sleep'] as num? ?? 0).toDouble(),
    );
  }
}