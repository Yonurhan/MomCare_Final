import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'dart:ui';

class PregnancyProgressCard extends StatelessWidget {
  final String dueDateString;

  const PregnancyProgressCard({Key? key, required this.dueDateString})
      : super(key: key);

  // Helper untuk mendapatkan detail mingguan (ukuran bayi & tips)
  Map<String, String> _getWeeklyDetails(int week) {
    const Map<int, List<String>> weeklyData = {
      4: ['Biji Chia', '🌱', 'Selamat! Anda sedang menumbuhkan kehidupan.'],
      8: [
        'Buah Raspberry',
        '🍓',
        'Jantung mungilnya kini berdetak untuk Anda.'
      ],
      12: ['Jeruk Nipis', '🍋', 'Refleksnya mulai terbentuk. Sungguh ajaib!'],
      16: ['Alpukat', '🥑', 'Dengarkan tubuh Anda, istirahatlah saat lelah.'],
      20: ['Pisang', '🍌', 'Setengah perjalanan! Rayakan momen indah ini.'],
      24: ['Jagung', '🌽', 'Setiap gerakan kecil adalah sapaan darinya.'],
      28: ['Terong', '🍆', 'Dia bisa mendengar suara Anda. Ajaklah ia bicara.'],
      32: ['Kelapa', '🥥', 'Percayai kekuatan tubuh Anda. Anda luar biasa!'],
      36: [
        'Sawi Putih',
        '🥬',
        'Setiap hari adalah langkah lebih dekat untuk bertemu.'
      ],
      40: ['Semangka', '🍉', 'Penantian terindah akan segera berakhir.'],
    };

    // Cari data untuk minggu terdekat
    int closestWeek = weeklyData.keys
        .firstWhere((k) => k >= week, orElse: () => weeklyData.keys.last);

    return {
      'size': weeklyData[closestWeek]![0],
      'emoji': weeklyData[closestWeek]![1],
      'tip': weeklyData[closestWeek]![2],
    };
  }

  @override
  Widget build(BuildContext context) {
    // --- Logika Kalkulasi (Tetap sama) ---
    int week = 1;
    String trimesterText = 'Trimester Pertama';
    int daysRemaining = 280;
    double progressPercent = 0.0;
    Map<String, String> weeklyDetails = _getWeeklyDetails(1);
    int daysPassed = 0;

    final dueDate = DateTime.tryParse(dueDateString);
    if (dueDate != null) {
      final now = DateTime.now();
      daysRemaining =
          dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (daysRemaining < 0) daysRemaining = 0;
      if (daysRemaining > 280) daysRemaining = 280;

      daysPassed = 280 - daysRemaining;
      week = (daysPassed / 7).ceil();
      if (week <= 0) week = 1;
      if (week > 40) week = 40;

      weeklyDetails = _getWeeklyDetails(week);
      progressPercent = week / 40.0;

      if (week <= 13)
        trimesterText = 'Trimester Pertama';
      else if (week <= 27)
        trimesterText = 'Trimester Kedua';
      else
        trimesterText = 'Trimester Ketiga';
    }
    // --- Akhir Logika ---

    // Palet Warna "Pastel Dream Gradient"
    const Color textPrimary = Color(0xFF5E545A); // Charcoal lembut
    const Color textSecondary = Color(0xFF8C7A8A); // Abu-abu hangat keunguan
    const Color accentColor = Color(0xFFE5B8C8); // Pink pastel
    const Color accentColorLight = Color(0xFFF3E9F1); // Lavender sangat terang

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFDEEEC), // Peach
            Color.fromARGB(255, 255, 255, 255), // Pink
            Color(0xFFE9E7F9) // Lavender
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE5B8C8).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Text(
            'Minggu Ke-$week',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trimesterText,
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // --- Statistik Ringkas ---
          _buildStatsRow(
            weeklyDetails['emoji']!,
            weeklyDetails['size']!,
            daysRemaining,
            textSecondary,
          ),
          const SizedBox(height: 24),

          // --- Progress Bar ---
          _buildProgressBar(
            progressPercent,
            daysPassed,
            daysRemaining,
            accentColor,
            accentColorLight,
            textSecondary,
          ),

          // --- Pemisah ---
          Divider(
            height: 48,
            color: Colors.black.withOpacity(0.06),
            thickness: 1,
          ),

          // --- Tips Mingguan ---
          _buildWeeklyTip(
            weeklyDetails['tip']!,
            accentColor,
            textPrimary,
          ),
        ],
      ),
    );
  }

  // Widget helper untuk baris statistik
  Widget _buildStatsRow(
      String emoji, String size, int daysRemaining, Color textColor) {
    return Row(
      children: [
        // Ukuran Janin
        Icon(Icons.child_care_outlined, color: textColor, size: 18),
        const SizedBox(width: 8),
        Text(
          '$emoji  $size',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(), // Memberi jarak
        // Sisa Hari
        Icon(Icons.hourglass_bottom_outlined, color: textColor, size: 18),
        const SizedBox(width: 8),
        Text(
          '$daysRemaining hari lagi',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Widget helper untuk progress bar
  Widget _buildProgressBar(
    double percent,
    int passed,
    int remaining,
    Color accentColor,
    Color accentColorLight,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearPercentIndicator(
          percent: percent,
          lineHeight: 8,
          animation: true,
          backgroundColor: accentColorLight,
          progressColor: accentColor,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Text(
          '${(percent * 100).toStringAsFixed(0)}% perjalanan telah dilalui',
          style: TextStyle(color: textColor, fontSize: 12),
        ),
      ],
    );
  }

  // Widget helper untuk tips mingguan
  Widget _buildWeeklyTip(String tip, Color accentColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, color: accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.9),
              fontStyle: FontStyle.italic,
              height: 1.5, // Jarak antar baris
            ),
          ),
        ),
      ],
    );
  }
}
