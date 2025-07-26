import 'package:flutter/foundation.dart';
import 'alert.dart';
import 'weekly_goal.dart';

// Kelas utama yang membungkus seluruh respons
class AssessmentResult {
  final String status;
  final Results? results;
  final DateTime? createdAt;

  AssessmentResult({
    required this.status,
    this.results,
    this.createdAt,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      status: json['status'],
      results:
          json['results'] != null ? Results.fromJson(json['results']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}

// Kelas untuk objek 'results'
class Results {
  final RiskOverview riskOverview;
  final List<WeeklyGoal> weeklyGoals;
  final MealPlanIdea mealPlanIdea;
  final List<Alert> alerts;
  final UserContext userContext;

  Results({
    required this.riskOverview,
    required this.weeklyGoals,
    required this.mealPlanIdea,
    required this.alerts,
    required this.userContext,
  });

  factory Results.fromJson(Map<String, dynamic> json) {
    return Results(
      riskOverview: RiskOverview.fromJson(json['risk_overview']),
      weeklyGoals: (json['weekly_goals'] as List)
          .map((goal) => WeeklyGoal.fromJson(goal))
          .toList(),
      mealPlanIdea: MealPlanIdea.fromJson(json['meal_plan_idea']),
      alerts: (json['alerts'] as List)
          .map((alert) => Alert.fromJson(alert))
          .toList(),
      userContext: UserContext.fromJson(json['user_context']),
    );
  }
}

// Kelas-kelas pendukung lainnya
class RiskOverview {
  final double highestRiskScore;
  final String mainFocus;

  RiskOverview({required this.highestRiskScore, required this.mainFocus});

  factory RiskOverview.fromJson(Map<String, dynamic> json) {
    return RiskOverview(
      highestRiskScore: (json['highest_risk_score'] as num).toDouble(),
      mainFocus: json['main_focus'],
    );
  }
}

class MealPlanIdea {
  final String breakfast;
  final String lunch;
  final String dinner;

  MealPlanIdea(
      {required this.breakfast, required this.lunch, required this.dinner});

  factory MealPlanIdea.fromJson(Map<String, dynamic> json) {
    return MealPlanIdea(
      breakfast: json['breakfast'],
      lunch: json['lunch'],
      dinner: json['dinner'],
    );
  }
}

class UserContext {
  final String trimester;
  // Anda bisa membuat model lebih detail untuk preferences dan health_profile jika perlu
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> healthProfile;

  UserContext(
      {required this.trimester,
      required this.preferences,
      required this.healthProfile});

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      trimester: json['trimester'],
      preferences: json['preferences'],
      healthProfile: json['health_profile'],
    );
  }
}
