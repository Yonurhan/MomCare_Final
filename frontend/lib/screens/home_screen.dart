import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

// Impor semua model dan service yang relevan
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/nutrition_summary_model.dart';

// Impor layar dan widget kustom Anda
import 'morning_sickness_screen.dart';
import 'nutrition_screen.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<NutritionSummary>? _nutritionSummaryFuture;
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _refreshData(); 
  }

  Future<NutritionSummary> _fetchNutritionData() async {
    await Provider.of<AuthService>(context, listen: false).refreshUserProfile();
    return _apiService.getNutritionSummary();
  }

  void _refreshData() {
    setState(() {
      _nutritionSummaryFuture = _fetchNutritionData();
    });
  }

  Future<void> _navigateToNutritionScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NutritionScreen()),
    );
    _refreshData();
  }
  
  Future<void> _logWater() async {
    await _apiService.logWater();
    _refreshData();
  }

  Future<void> _logSleep() async {
    await _apiService.logSleep(hours: 1.0);
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KARTU PROGRES DARI KODE LAMA ANDA ---
              _OldPregnancyProgressCard(),
              
              // --- KARTU NUTRISI BARU YANG DISISIPKAN ---
              FutureBuilder<NutritionSummary>(
                future: _nutritionSummaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Gagal memuat data nutrisi: ${snapshot.error}')));
                  }
                  if (snapshot.hasData) {
                    final summary = snapshot.data!;
                    return _TodayNutritionCard(
                      summary: summary,
                      onWaterLogged: _logWater,
                      onSleepLogged: _logSleep,
                    );
                  }
                  return const SizedBox(height: 200, child: Center(child: Text('Data nutrisi tidak tersedia.')));
                },
              ),

              // --- GRID FITUR DARI KODE LAMA ANDA ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text('Quick Access', style: Theme.of(context).textTheme.headlineMedium),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  FeatureCard(
                    icon: Icons.restaurant,
                    title: AppConstants.nutritionFeature,
                    color: AppTheme.accentColor,
                    onTap: _navigateToNutritionScreen,
                  ),
                  FeatureCard(
                    icon: Icons.sick,
                    title: AppConstants.morningSicknessFeature,
                    color: AppTheme.accentColor,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MorningSicknessScreen()));
                    },
                  ),
                  FeatureCard(
                    icon: Icons.monitor_weight,
                    title: AppConstants.weightTrackerFeature,
                    color: AppTheme.accentColor,
                    onTap: () {},
                  ),
                  FeatureCard(
                    icon: Icons.calendar_today,
                    title: AppConstants.appointmentsFeature,
                    color: AppTheme.accentColor,
                    onTap: () {},
                  ),
                ],
              ),
              
              // --- KARTU TIPS HARIAN DARI KODE LAMA ANDA ---
              _DailyTipCard(),

              // --- KARTU JANJI TEMU DARI KODE LAMA ANDA ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Text('Upcoming Appointments', style: Theme.of(context).textTheme.headlineMedium),
              ),
              const SizedBox(height: 16),
              _AppointmentCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET DARI KODE LAMA ANDA (DENGAN PERBAIKAN) ---
class _OldPregnancyProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    int week = 0;
    String trimesterText = 'Trimester 1';
    int daysRemaining = 280;

    if (user?.dueDate != null) {
      final dueDate = DateTime.tryParse(user!.dueDate!);
      if (dueDate != null) {
        daysRemaining = dueDate.difference(DateTime.now()).inDays;
        if (daysRemaining < 0) daysRemaining = 0;
        
        final pregnancyDays = 280 - daysRemaining;
        week = (pregnancyDays / 7).ceil();

        if (week <= 13) trimesterText = AppConstants.firstTrimester;
        else if (week <= 27) trimesterText = AppConstants.secondTrimester;
        else trimesterText = AppConstants.thirdTrimester;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  Text('${AppConstants.weekLabel} $week', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(trimesterText, style: const TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$daysRemaining days to go', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearPercentIndicator(
            percent: week / 40.0,
            lineHeight: 10,
            backgroundColor: Colors.white.withOpacity(0.3),
            progressColor: Colors.white,
            barRadius: const Radius.circular(5),
            padding: EdgeInsets.zero,
          ),
          // --- INDIKATOR MINGGU DARI KODE LAMA ANDA ---
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeekIndicator('1', true),
              _buildWeekIndicator('12', true),
              _buildWeekIndicator('24', false),
              _buildWeekIndicator('40', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekIndicator(String week, bool isPassed) {
    return Column(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPassed ? Colors.white : Colors.white.withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              week,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPassed ? AppTheme.primaryColor : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Week',
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }
}

// --- WIDGET BARU UNTUK KARTU NUTRISI ---
// (Tidak ada perubahan di sini)
class _TodayNutritionCard extends StatelessWidget {
  final NutritionSummary summary;
  final VoidCallback onWaterLogged;
  final VoidCallback onSleepLogged;

  const _TodayNutritionCard({required this.summary, required this.onWaterLogged, required this.onSleepLogged});

  @override
  Widget build(BuildContext context) {
    // ... kode sama seperti sebelumnya
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutrisi Hari Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 120, height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: summary.goals.calories > 0 ? min(summary.consumed.calories / summary.goals.calories, 1.0) : 0.0,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${summary.consumed.calories.toInt()}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('/ ${summary.goals.calories.toInt()} kkal', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _NutrientStat(label: 'Karbohidrat', consumed: summary.consumed.carbs, goal: summary.goals.carbs, unit: 'g', color: Colors.orange),
                    const SizedBox(height: 12),
                    _NutrientStat(label: 'Protein', consumed: summary.consumed.protein, goal: summary.goals.protein, unit: 'g', color: Colors.pinkAccent),
                    const SizedBox(height: 12),
                    _NutrientStat(label: 'Lemak', consumed: summary.consumed.fat, goal: summary.goals.fat, unit: 'g', color: Colors.lightBlue),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 40),
          Row(
            children: [
              Expanded(child: _ExtraLogItem(title: "Air Minum", value: "${(summary.consumed.water / 250).toInt()} Gelas", percent: summary.goals.waterMl > 0 ? min(summary.consumed.water / summary.goals.waterMl, 1.0) : 0.0, color: Colors.lightBlue, onAdd: onWaterLogged)),
              const SizedBox(width: 16),
              Expanded(child: _ExtraLogItem(title: "Tidur", value: "${summary.consumed.sleep.toStringAsFixed(1)} Jam", percent: summary.goals.sleepHours > 0 ? min(summary.consumed.sleep / summary.goals.sleepHours, 1.0) : 0.0, color: Colors.purpleAccent, onAdd: onSleepLogged)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientStat extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final Color color;
  final String unit;

  const _NutrientStat({required this.label, required this.consumed, required this.goal, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text('${consumed.toInt()}/${goal.toInt()}$unit', style: const TextStyle(fontWeight: FontWeight.bold)),
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

class _ExtraLogItem extends StatelessWidget {
  final String title;
  final String value;
  final double percent;
  final Color color;
  final VoidCallback onAdd;

  const _ExtraLogItem({required this.title, required this.value, required this.percent, required this.color, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 24, height: 24,
              child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.add_circle, size: 24), color: color, onPressed: onAdd),
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
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}

// --- WIDGET DARI KODE LAMA ANDA ---
class _DailyTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(AppConstants.dailyTipLabel, style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Try eating small, frequent meals to help manage morning sickness. Keep crackers by your bedside to eat before getting up.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MorningSicknessScreen()),
                    );
                  },
                  child: const Text('Read More'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DARI KODE LAMA ANDA ---
class _AppointmentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Prenatal Checkup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('March 25, 2025 • 10:00 AM', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.secondaryTextColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}