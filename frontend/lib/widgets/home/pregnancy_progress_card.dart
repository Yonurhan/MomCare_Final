import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class PregnancyProgressCard extends StatelessWidget {
  final String dueDateString;

  const PregnancyProgressCard({Key? key, required this.dueDateString})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Logic to calculate progress ---
    int week = 0;
    String trimesterText = 'Trimester 1';
    int daysRemaining = 280;
    double progressPercent = 0.0;

    final dueDate = DateTime.tryParse(dueDateString);
    if (dueDate != null) {
      daysRemaining = dueDate.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) daysRemaining = 0;

      final pregnancyDays = 280 - daysRemaining;
      week = (pregnancyDays / 7).ceil();
      progressPercent = week / 40.0;
      if (progressPercent > 1.0) progressPercent = 1.0;

      if (week <= 13)
        trimesterText = 'Trimester Pertama';
      else if (week <= 27)
        trimesterText = 'Trimester Kedua';
      else
        trimesterText = 'Trimester Ketiga';
    }
    // --- End of Logic ---

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade300, Colors.deepPurple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minggu Ke-$week',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(trimesterText,
                      style: TextStyle(
                          fontSize: 16, color: Colors.white.withOpacity(0.9))),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$daysRemaining hari lagi',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearPercentIndicator(
            percent: progressPercent,
            lineHeight: 12,
            backgroundColor: Colors.white.withOpacity(0.3),
            progressColor: Colors.white,
            barRadius: const Radius.circular(6),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
