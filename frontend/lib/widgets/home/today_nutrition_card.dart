import 'dart:math';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../models/nutrition_summary_model.dart';
import '../../theme/app_theme.dart'; // Asumsi Anda punya file theme

class TodayNutritionCard extends StatelessWidget {
  final NutritionSummary summary;
  final VoidCallback onWaterLogged;
  final VoidCallback onSleepLogged;

  const TodayNutritionCard({
    Key? key,
    required this.summary,
    required this.onWaterLogged,
    required this.onSleepLogged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Nutrisi Hari Ini',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildCaloriesCircle(summary),
              const SizedBox(width: 24),
              _buildMacronutrientBars(summary),
            ],
          ),
          const Divider(height: 40, thickness: 1, indent: 8, endIndent: 8),
          Row(
            children: [
              Expanded(
                child: _ExtraLogItem(
                  title: "Air Minum",
                  value: "${(summary.consumed.water / 250).toInt()} Gelas",
                  percent: summary.goals.waterMl > 0
                      ? min(summary.consumed.water / summary.goals.waterMl, 1.0)
                      : 0.0,
                  color: Colors.blue.shade400,
                  icon: Icons.water_drop,
                  onAdd: onWaterLogged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ExtraLogItem(
                  title: "Waktu Tidur",
                  value: "${summary.consumed.sleep.toStringAsFixed(1)} Jam",
                  percent: summary.goals.sleepHours > 0
                      ? min(summary.consumed.sleep / summary.goals.sleepHours,
                          1.0)
                      : 0.0,
                  color: Colors.purple.shade400,
                  icon: Icons.nightlight_round,
                  onAdd: onSleepLogged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCircle(NutritionSummary summary) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: summary.goals.calories > 0
                ? min(summary.consumed.calories / summary.goals.calories, 1.0)
                : 0.0,
            strokeWidth: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade300),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${summary.consumed.calories.toInt()}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                Text(
                  '/ ${summary.goals.calories.toInt()} kkal',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientBars(NutritionSummary summary) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _NutrientStat(
              label: 'Karbohidrat',
              consumed: summary.consumed.carbs,
              goal: summary.goals.carbs,
              unit: 'g',
              color: Colors.orange),
          const SizedBox(height: 16),
          _NutrientStat(
              label: 'Protein',
              consumed: summary.consumed.protein,
              goal: summary.goals.protein,
              unit: 'g',
              color: Colors.teal),
          const SizedBox(height: 16),
          _NutrientStat(
              label: 'Lemak',
              consumed: summary.consumed.fat,
              goal: summary.goals.fat,
              unit: 'g',
              color: Colors.blueAccent),
        ],
      ),
    );
  }
}

// Sub-widget for macronutrients, specific to this card
class _NutrientStat extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final Color color;
  final String unit;

  const _NutrientStat(
      {required this.label,
      required this.consumed,
      required this.goal,
      required this.color,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('${consumed.toInt()}/${goal.toInt()}$unit',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: goal > 0 ? min(consumed / goal, 1.0) : 0.0,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

// Sub-widget for water/sleep, specific to this card
class _ExtraLogItem extends StatelessWidget {
  final String title;
  final String value;
  final double percent;
  final Color color;
  final IconData icon;
  final VoidCallback onAdd;

  const _ExtraLogItem(
      {required this.title,
      required this.value,
      required this.percent,
      required this.color,
      required this.onAdd,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_circle, size: 28),
                color: color,
                onPressed: onAdd,
              ),
            )
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
