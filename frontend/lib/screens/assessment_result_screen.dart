import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Impor model, service, dan widget yang relevan
import '../models/assessment_result.dart';
import '../models/alert.dart';
import '../models/recommendation.dart';
import '../models/weekly_goal.dart';
import '../services/assessment_service.dart';
import 'home_screen.dart'; // Untuk kembali ke home

class AssessmentResultScreen extends StatefulWidget {
  final int assessmentId;

  const AssessmentResultScreen({Key? key, required this.assessmentId})
      : super(key: key);

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen> {
  late Future<AssessmentResult> _assessmentResultFuture;

  @override
  void initState() {
    super.initState();
    // Ambil service dari Provider dan mulai proses pengambilan data
    final assessmentService =
        Provider.of<AssessmentService>(context, listen: false);
    _assessmentResultFuture =
        assessmentService.getAssessmentResult(widget.assessmentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Laporan Kesehatan Anda'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false, // Sembunyikan tombol kembali default
      ),
      body: FutureBuilder<AssessmentResult>(
        future: _assessmentResultFuture,
        builder: (context, snapshot) {
          // --- State 1: Loading (Polling Backend) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingStateWidget();
          }
          // --- State 2: Error ---
          if (snapshot.hasError) {
            return _ErrorStateWidget(
              error: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  final assessmentService =
                      Provider.of<AssessmentService>(context, listen: false);
                  _assessmentResultFuture = assessmentService
                      .getAssessmentResult(widget.assessmentId);
                });
              },
            );
          }
          // --- State 3: Data Received ---
          if (snapshot.hasData) {
            final results = snapshot.data!.results;
            if (results == null) {
              return _ErrorStateWidget(
                  error: 'Data hasil tidak valid.', onRetry: () {});
            }
            return _buildResultsContent(context, results);
          }
          // --- Fallback ---
          return const Center(
              child: Text('Terjadi kesalahan yang tidak diketahui.'));
        },
      ),
    );
  }

  // --- Widget untuk Konten Hasil ---
  Widget _buildResultsContent(BuildContext context, Results results) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildRiskOverviewCard(results.riskOverview),
        const SizedBox(height: 24),
        _buildSectionHeader('🎯 Prioritas Minggu Ini'),
        _buildGoalsCard(results.weeklyGoals),
        const SizedBox(height: 24),
        _buildSectionHeader('🥗 Ide Rencana Makan'),
        _buildMealPlanCard(results.mealPlanIdea),
        const SizedBox(height: 24),
        _buildSectionHeader('🚨 Peringatan & Saran Detail'),
        ...results.alerts.map((alert) => _buildAlertCard(alert)).toList(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.pink.shade400,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Selesai & Kembali ke Beranda',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  // --- Helper Widgets untuk setiap bagian ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildRiskOverviewCard(RiskOverview overview) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.pink.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.purple.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fokus Utama Anda',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          Text(overview.mainFocus,
              style: TextStyle(
                  fontSize: 22,
                  color: Colors.purple.shade800,
                  fontWeight: FontWeight.bold)),
          const Divider(height: 24, thickness: 1),
          Row(
            children: [
              const Text('Skor Risiko Tertinggi: ',
                  style: TextStyle(color: Colors.black54, fontSize: 14)),
              Text(overview.highestRiskScore.toStringAsFixed(1),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGoalsCard(List<WeeklyGoal> goals) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: goals
              .map((goal) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade100,
                      child: Text('#${goal.priority}',
                          style: TextStyle(
                              color: Colors.purple.shade800,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(goal.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(goal.description),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMealPlanCard(MealPlanIdea mealPlan) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildMealItem('Sarapan', mealPlan.breakfast,
                Icons.free_breakfast_outlined, Colors.orange),
            const Divider(height: 24),
            _buildMealItem('Makan Siang', mealPlan.lunch,
                Icons.lunch_dining_outlined, Colors.green),
            const Divider(height: 24),
            _buildMealItem('Makan Malam', mealPlan.dinner,
                Icons.dinner_dining_outlined, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(
      String title, String description, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(color: Colors.grey[700], height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final Color color;
    switch (alert.level) {
      case 'WARNING':
        color = Colors.orange.shade700;
        break;
      case 'DANGER':
        color = Colors.red.shade700;
        break;
      case 'INFO':
      default:
        color = Colors.blue.shade700;
        break;
    }
    final IconData icon;
    switch (alert.category) {
      case 'nutrition':
        icon = Icons.restaurant_menu_outlined;
        break;
      case 'symptom_management':
        icon = Icons.healing_outlined;
        break;
      default:
        icon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 24)),
        title: Text(alert.title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text('Skor Risiko: ${alert.riskScore.toStringAsFixed(1)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.message,
              style: const TextStyle(fontStyle: FontStyle.italic)),
          const Divider(height: 24),
          if (alert.lifestyleTips.isNotEmpty) ...[
            const Text('💡 Gaya Hidup Sehat:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...alert.lifestyleTips.map((tip) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check, color: Colors.green),
                  title: Text(tip),
                  dense: true,
                )),
          ],
          if (alert.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('🍽️ Rekomendasi Spesifik:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...alert.recommendations
                .map((rec) => _buildRecommendationItem(rec)),
          ]
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(Recommendation rec) {
    if (rec is FoodRecommendation) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.fastfood_outlined, color: Colors.orange.shade800),
        title: Text('${rec.food} (${rec.servingSize})'),
        subtitle: Text('Kontribusi: ${rec.value} ${rec.unit}'),
        dense: true,
      );
    }
    if (rec is InfoRecommendation) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.info_outline, color: Colors.blue.shade800),
        title: Text(rec.text),
        dense: true,
      );
    }
    return const SizedBox.shrink(); // Fallback
  }
}

// --- Widget untuk State Loading ---
class _LoadingStateWidget extends StatelessWidget {
  const _LoadingStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.pink),
          const SizedBox(height: 24),
          const Text(
            'Menganalisis Jawaban Anda...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Harap tunggu sebentar, kami sedang\nmenyiapkan laporan personal untuk Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// --- Widget untuk State Error ---
class _ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorStateWidget(
      {Key? key, required this.error, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text("Oops, terjadi kesalahan!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }
}
