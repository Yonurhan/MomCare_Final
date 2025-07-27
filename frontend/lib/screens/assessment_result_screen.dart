import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Impor model, service, dan widget yang relevan (pastikan path sudah benar)
import '../models/assessment_result.dart';
import '../models/alert.dart';
import '../models/recommendation.dart';
import '../models/weekly_goal.dart';
import '../services/assessment_service.dart';
import 'home_screen.dart'; // Untuk kembali ke home

// --- PALET WARNA & GAYA UNTUK DESAIN BARU ---
const Color _primaryColor = Color(0xFF7B4B94);
const Color _accentColor = Color(0xFFF06292);
const Color _lightTextColor = Color(0xFF757575);
const Color _darkTextColor = Color(0xFF212121);
const Color _scaffoldBgColor = Color(0xFFF8F8F8);

class AssessmentResultScreen extends StatefulWidget {
  final int assessmentId;

  const AssessmentResultScreen({super.key, required this.assessmentId});

  @override
  State<AssessmentResultScreen> createState() => _AssessmentResultScreenState();
}

class _AssessmentResultScreenState extends State<AssessmentResultScreen>
    with SingleTickerProviderStateMixin {
  late Future<AssessmentResult> _assessmentResultFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final assessmentService =
        Provider.of<AssessmentService>(context, listen: false);
    _assessmentResultFuture =
        assessmentService.getAssessmentResult(widget.assessmentId);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --- HELPERS UNTUK GAYA KONSISTEN ---

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  TextStyle _getHeadlineStyle({Color color = _darkTextColor}) {
    return GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      fontSize: 18,
      color: color,
    );
  }

  TextStyle _getSubtitleStyle() {
    return GoogleFonts.lato(
      fontSize: 14,
      color: _lightTextColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      appBar: AppBar(
        title: Text('Laporan Anda',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: _darkTextColor)),
        centerTitle: true,
        backgroundColor: _scaffoldBgColor,
        elevation: 0,
        foregroundColor: _darkTextColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: _primaryColor),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<AssessmentResult>(
        future: _assessmentResultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingStateWidget();
          }
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
          if (snapshot.hasData) {
            final results = snapshot.data!.results;
            if (results == null) {
              return _ErrorStateWidget(
                  error: 'Data hasil tidak valid.', onRetry: () {});
            }
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildResultsContent(context, results),
            );
          }
          return const Center(
              child: Text('Terjadi kesalahan yang tidak diketahui.'));
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tentang Laporan', style: _getHeadlineStyle()),
        content: Text(
          'Laporan ini memberikan analisis kesehatan pribadi berdasarkan jawaban Anda. Prioritas dan rekomendasi disesuaikan untuk Anda.',
          style: _getSubtitleStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Mengerti', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  ListView _buildResultsContent(BuildContext context, Results results) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeaderCard(), // Header baru
        const SizedBox(height: 24),
        _buildRiskOverviewCard(results.riskOverview),
        const SizedBox(height: 24),
        _buildSectionHeader('🎯 Prioritas Minggu Ini',
            'Fokus pada hal-hal penting terlebih dahulu'),
        _buildGoalsCard(results.weeklyGoals),
        const SizedBox(height: 24),
        _buildSectionHeader('🥗 Ide Rencana Makan',
            'Saran nutrisi yang sesuai dengan kebutuhan Anda'),
        _buildMealPlanCard(results.mealPlanIdea),
        const SizedBox(height: 24),
        _buildSectionHeader(
            '🚨 Peringatan & Saran Detail', 'Area yang perlu perhatian khusus'),
        ...List.generate(
          results.alerts.length,
          (index) => AnimatedAlertCard(
              alert: results.alerts[index], index: index), // Kartu Alert baru
        ),
        const SizedBox(height: 32),
        _buildCompletionButton(context),
        const SizedBox(height: 24),
        _buildFooter(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _darkTextColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: _getSubtitleStyle()),
        ],
      ),
    );
  }

  // --- HEADER BARU YANG LEBIH INDAH ---
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor,
            _accentColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.health_and_safety_outlined,
              color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text(
            'Laporan Kesehatan Anda',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Berikut adalah ringkasan, saran, dan prioritas kesehatan yang telah disesuaikan untuk Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskOverviewCard(RiskOverview overview) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _buildCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FOKUS UTAMA ANDA',
              style: GoogleFonts.lato(
                  color: _lightTextColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(overview.mainFocus,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  color: _primaryColor,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildRiskGauge(overview.highestRiskScore),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getRiskLevel(overview.highestRiskScore),
                        style: _getHeadlineStyle(
                            color: _getRiskColor(overview.highestRiskScore))),
                    const SizedBox(height: 4),
                    Text(
                      _getRiskDescription(overview.highestRiskScore),
                      style: _getSubtitleStyle(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskGauge(double score) {
    final color = _getRiskColor(score);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 10.0,
            strokeWidth: 6,
            backgroundColor: color.withOpacity(0.2),
            color: color,
          ),
          Center(
            child: Text(score.toStringAsFixed(1),
                style: GoogleFonts.poppins(
                    fontSize: 18, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(double score) {
    if (score <= 3.9) return Colors.green.shade600;
    if (score <= 6.9) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _getRiskLevel(double score) {
    if (score <= 3.9) return 'Risiko Rendah';
    if (score <= 6.9) return 'Risiko Sedang';
    return 'Risiko Tinggi';
  }

  String _getRiskDescription(double score) {
    if (score <= 3.9) return 'Pertahankan gaya hidup sehat Anda.';
    if (score <= 6.9) return 'Perlu perhatian pada beberapa area.';
    return 'Dianjurkan untuk segera bertindak.';
  }

  Widget _buildGoalsCard(List<WeeklyGoal> goals) {
    return Container(
      decoration: _buildCardDecoration(),
      child: Column(
        children: goals.map((goal) => AnimatedGoalItem(goal: goal)).toList(),
      ),
    );
  }

  Widget _buildMealPlanCard(MealPlanIdea mealPlan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: _buildCardDecoration(),
      child: Column(
        children: [
          _buildMealItem('Sarapan', mealPlan.breakfast,
              Icons.free_breakfast_outlined, Colors.orange),
          const Divider(height: 24, indent: 16, endIndent: 16),
          _buildMealItem('Makan Siang', mealPlan.lunch,
              Icons.lunch_dining_outlined, Colors.green),
          const Divider(height: 24, indent: 16, endIndent: 16),
          _buildMealItem('Makan Malam', mealPlan.dinner,
              Icons.dinner_dining_outlined, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildMealItem(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _getHeadlineStyle()),
                const SizedBox(height: 4),
                Text(description, style: _getSubtitleStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            'Selesai & Kembali ke Beranda',
            style: GoogleFonts.poppins(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Laporan ini bersifat rekomendasi umum. Konsultasikan dengan profesional kesehatan untuk diagnosis akurat.',
        textAlign: TextAlign.center,
        style: _getSubtitleStyle().copyWith(fontSize: 12),
      ),
    );
  }
}

// --- WIDGET-WIDGET ANAK YANG SUDAH DIDESAIN ULANG ---

class AnimatedGoalItem extends StatelessWidget {
  final WeeklyGoal goal;
  const AnimatedGoalItem({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final colors = [_accentColor, Colors.orange, Colors.blue, Colors.green];
    final color = colors[goal.priority % colors.length];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: Container(
        width: 6,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(
        goal.title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          goal.description,
          style: GoogleFonts.lato(color: _lightTextColor, fontSize: 14),
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: _lightTextColor, size: 16),
      onTap: () {},
    );
  }
}

// --- KARTU ALERT YANG SUDAH DIPERBAIKI TOTAL ---
class AnimatedAlertCard extends StatefulWidget {
  final Alert alert;
  final int index;

  const AnimatedAlertCard(
      {super.key, required this.alert, required this.index});

  @override
  State<AnimatedAlertCard> createState() => _AnimatedAlertCardState();
}

class _AnimatedAlertCardState extends State<AnimatedAlertCard> {
  // Helper untuk mendapatkan warna dan ikon berdasarkan data
  Color _getColorForAlert() {
    switch (widget.alert.level) {
      case 'WARNING':
        return Colors.orange.shade700;
      case 'DANGER':
        return Colors.red.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  IconData _getIconForAlert() {
    switch (widget.alert.category) {
      case 'nutrition':
        return Icons.restaurant_menu_outlined;
      case 'symptom_management':
        return Icons.healing_outlined;
      case 'exercise':
        return Icons.directions_run_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // Fungsi yang hilang, sekarang ditambahkan kembali
  String _getRecommendationText(Recommendation rec) {
    if (rec is FoodRecommendation) {
      return '${rec.food} (${rec.servingSize}) - ${rec.value} ${rec.unit}';
    }
    if (rec is InfoRecommendation) {
      return rec.text;
    }
    return '';
  }

  Widget _buildTipSection({required String title, required List<String> tips}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 15, color: _darkTextColor),
        ),
        const SizedBox(height: 12),
        ...tips.asMap().entries.map((entry) {
          int idx = entry.key;
          String tip = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (idx * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Padding(
                  padding: EdgeInsets.only(top: value * 8, bottom: 8),
                  child: child,
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.lato(
                        color: _lightTextColor, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForAlert();
    final icon = _getIconForAlert();

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Icon(icon, color: color, size: 28),
          title: Text(
            widget.alert.title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
          subtitle: Text(
            'Skor Risiko: ${widget.alert.riskScore.toStringAsFixed(1)}',
            style:
                GoogleFonts.lato(color: color.withOpacity(0.8), fontSize: 13),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                widget.alert.message,
                style: GoogleFonts.lato(
                    fontStyle: FontStyle.italic,
                    color: _lightTextColor,
                    fontSize: 14),
              ),
            ),
            if (widget.alert.lifestyleTips.isNotEmpty) ...[
              _buildTipSection(
                title: '💡 Gaya Hidup Sehat',
                tips: widget.alert.lifestyleTips,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.alert.recommendations.isNotEmpty) ...[
              _buildTipSection(
                title: '🍽️ Rekomendasi Spesifik',
                tips: widget.alert.recommendations
                    .map((rec) => _getRecommendationText(rec))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingStateWidget extends StatelessWidget {
  const _LoadingStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 24),
          Text(
            'Menganalisis Jawaban Anda...',
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _darkTextColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar.',
            style: GoogleFonts.lato(fontSize: 14, color: _lightTextColor),
          ),
        ],
      ),
    );
  }
}

class _ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorStateWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                color: Colors.red.shade400, size: 64),
            const SizedBox(height: 24),
            Text(
              "Oops, Terjadi Kesalahan!",
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _darkTextColor),
            ),
            const SizedBox(height: 16),
            Text(
              "Kami tidak dapat memuat laporan kesehatan Anda. Silakan coba lagi.",
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 15, color: _lightTextColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
