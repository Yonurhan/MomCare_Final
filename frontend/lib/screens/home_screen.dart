import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/home_view_model.dart';
import '../widgets/home/welcome_header.dart';
import '../widgets/home/weekly_assessment_card.dart';
import '../widgets/home/assessment_complete_card.dart';
import '../widgets/home/pregnancy_progress_card.dart';
import '../widgets/home/today_nutrition_card.dart';
import '../widgets/home/home_section_header.dart';
import '../widgets/feature_card.dart';
import 'nutrition_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: RefreshIndicator(
            onRefresh: viewModel.fetchData,
            color: Colors.pink,
            child: _buildContent(context, viewModel),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.pink));
    }

    if (viewModel.errorMessage != null) {
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
              Text(viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: viewModel.fetchData,
                  child: const Text("Coba Lagi")),
            ],
          ),
        ),
      );
    }

    Future<void> navigateToNutritionScreen() async {
      await Navigator.push(context,
          MaterialPageRoute(builder: (context) => const NutritionScreen()));
      viewModel.fetchData();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WelcomeHeader(userName: viewModel.currentUser?.username ?? 'Bunda'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: viewModel.isAssessmentRequired
                ? WeeklyAssessmentCard(
                    onTap: () => viewModel.handleAssessmentNavigation(context))
                : AssessmentCompleteCard(
                    onTap: () => viewModel.handleAssessmentNavigation(context)),
          ),

          // --- PERUBAHAN DI SINI ---
          // Kondisi 'if' dinonaktifkan untuk sementara agar kartu selalu muncul.
          // Gunakan ini untuk memastikan tampilan kartu sudah benar.
          // if (viewModel.currentUser?.dueDate != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: PregnancyProgressCard(
              // Gunakan tanggal statis (hardcode) untuk pengujian.
              // Ganti dengan tanggal yang sesuai dalam format 'YYYY-MM-DD'.
              // Contoh ini menggunakan 20 April 2026.
              // Saat ini, 27 Juli 2025, ini setara dengan ~ minggu ke-9.
              dueDateString: '2026-03-25',

              // 💡 Setelah data dari ViewModel benar, hapus baris di atas dan
              //    kembalikan baris di bawah ini serta aktifkan lagi kondisi 'if'-nya.
              // dueDateString: viewModel.currentUser!.dueDate!,
            ),
          ),

          if (viewModel.nutritionSummary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: TodayNutritionCard(
                summary: viewModel.nutritionSummary!,
                onWaterLogged: viewModel.logWater,
                onSleepLogged: viewModel.logSleep,
              ),
            ),
          const HomeSectionHeader(title: 'Akses Cepat'),
          _buildFeatureGrid(context, navigateToNutritionScreen),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, VoidCallback onNutritionTap) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        FeatureCard(
            icon: Icons.restaurant_menu_outlined,
            title: 'Nutrisi',
            color: Colors.orange.shade300,
            onTap: onNutritionTap),
        FeatureCard(
            icon: Icons.sick_outlined,
            title: 'Mual',
            color: Colors.teal.shade300,
            onTap: () {}),
        FeatureCard(
            icon: Icons.monitor_weight_outlined,
            title: 'Berat Badan',
            color: Colors.blue.shade300,
            onTap: () {}),
        FeatureCard(
            icon: Icons.calendar_today_outlined,
            title: 'Janji Temu',
            color: Colors.purple.shade300,
            onTap: () {}),
      ],
    );
  }
}
