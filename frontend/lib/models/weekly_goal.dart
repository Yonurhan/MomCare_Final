class WeeklyGoal {
  final String description;
  final int priority;
  final String relatedAlertTitle;
  final String title;

  WeeklyGoal({
    required this.description,
    required this.priority,
    required this.relatedAlertTitle,
    required this.title,
  });

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) {
    return WeeklyGoal(
      description: json['description'],
      priority: json['priority'],
      relatedAlertTitle: json['related_alert_title'],
      title: json['title'],
    );
  }
}
