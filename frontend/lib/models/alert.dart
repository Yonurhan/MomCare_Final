import 'recommendation.dart';

class Alert {
  final String category;
  final String level;
  final List<String> lifestyleTips;
  final String message;
  final List<Recommendation> recommendations;
  final double riskScore;
  final String title;

  Alert({
    required this.category,
    required this.level,
    required this.lifestyleTips,
    required this.message,
    required this.recommendations,
    required this.riskScore,
    required this.title,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    var recommendationList = json['recommendations'] as List;
    // Menggunakan factory constructor di Recommendation untuk menangani tipe yang berbeda
    List<Recommendation> parsedRecommendations =
        recommendationList.map((rec) => Recommendation.fromJson(rec)).toList();

    return Alert(
      category: json['category'],
      level: json['level'],
      lifestyleTips: List<String>.from(json['lifestyle_tips']),
      message: json['message'],
      recommendations: parsedRecommendations,
      riskScore: (json['risk_score'] as num).toDouble(),
      title: json['title'],
    );
  }
}
