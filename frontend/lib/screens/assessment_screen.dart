import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Impor Service dan Layar Hasil yang relevan
import '../services/assessment_service.dart';
import '../services/auth_service.dart';
import 'assessment_result_screen.dart';

// --- ViewModel untuk Mengelola State Asesmen ---

class AssessmentViewModel extends ChangeNotifier {
  final AssessmentService _assessmentService;

  AssessmentViewModel({required AssessmentService assessmentService})
      : _assessmentService = assessmentService;

  final PageController pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  // Menyimpan semua jawaban dari form
  final Map<String, dynamic> _quizAnswers = {
    'general_symptoms': <String>[],
    'energy_level': 5.0,
    'nausea_severity': 'tidak_ada',
    'additional_notes': '',
  };

  // --- Getters ---
  int get currentPage => _currentPage;
  bool get isSubmitting => _isSubmitting;
  Map<String, dynamic> get quizAnswers => _quizAnswers;
  int get totalPages => 4; // Jumlah halaman dalam wizard
  double get progress => (_currentPage + 1) / totalPages;

  // --- Methods ---
  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPage < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void updateAnswer(String key, dynamic value) {
    _quizAnswers[key] = value;
    notifyListeners();
    print("Jawaban diperbarui: $_quizAnswers"); // Untuk debugging
  }

  Future<void> submitAssessment(BuildContext context) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final response = await _assessmentService.performAssessment(_quizAnswers);
      final int assessmentId = response['assessmentId'];

      // Jika berhasil, navigasi ke layar hasil
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AssessmentResultScreen(assessmentId: assessmentId),
        ),
      );
    } catch (e) {
      // Tampilkan pesan error jika gagal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim asesmen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

// --- Widget Utama Layar Asesmen ---

class AssessmentScreen extends StatelessWidget {
  const AssessmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AssessmentViewModel(
        // Ambil service dari provider yang sudah ada
        assessmentService: Provider.of<AssessmentService>(ctx, listen: false),
      ),
      child: const _AssessmentScreenContent(),
    );
  }
}

class _AssessmentScreenContent extends StatelessWidget {
  const _AssessmentScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AssessmentViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asesmen Kesehatan Mingguan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: LinearProgressIndicator(
            value: viewModel.progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink.shade300),
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: viewModel.pageController,
            onPageChanged: viewModel.onPageChanged,
            physics: const NeverScrollableScrollPhysics(), // Non-aktifkan swipe
            children: const [
              _QuestionPage1(), // Gejala umum
              _QuestionPage2(), // Tingkat energi
              _QuestionPage3(), // Tingkat mual
              _QuestionPage4(), // Catatan tambahan & submit
            ],
          ),
          if (viewModel.isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Mengirim data...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context, viewModel),
    );
  }

  Widget _buildBottomNavBar(
      BuildContext context, AssessmentViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol "Kembali"
          if (viewModel.currentPage > 0)
            TextButton(
              onPressed: viewModel.previousPage,
              child: const Text('Kembali', style: TextStyle(fontSize: 16)),
            ),

          const Spacer(),

          // Tombol "Selanjutnya" atau "Kirim"
          ElevatedButton(
            onPressed: () {
              if (viewModel.currentPage < viewModel.totalPages - 1) {
                viewModel.nextPage();
              } else {
                viewModel.submitAssessment(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              viewModel.currentPage < viewModel.totalPages - 1
                  ? 'Selanjutnya'
                  : 'Kirim Asesmen',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Halaman-Halaman Pertanyaan ---

class _QuestionPage1 extends StatelessWidget {
  const _QuestionPage1({Key? key}) : super(key: key);

  static const List<String> availableSymptoms = [
    'kelelahan',
    'mual',
    'sakit punggung',
    'pusing',
    'kram kaki',
    'sembelit'
  ];

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer agar widget ini rebuild saat jawaban berubah
    return Consumer<AssessmentViewModel>(
      builder: (context, viewModel, child) {
        final List<String> selectedSymptoms =
            List<String>.from(viewModel.quizAnswers['general_symptoms']);

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Gejala Apa Saja yang Anda Rasakan Minggu Ini?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih semua yang sesuai. Ini membantu kami memberikan saran yang lebih personal.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ...availableSymptoms.map((symptom) {
              return CheckboxListTile(
                title: Text(symptom[0].toUpperCase() + symptom.substring(1),
                    style: const TextStyle(fontSize: 18)),
                value: selectedSymptoms.contains(symptom),
                onChanged: (bool? value) {
                  if (value == true) {
                    selectedSymptoms.add(symptom);
                  } else {
                    selectedSymptoms.remove(symptom);
                  }
                  viewModel.updateAnswer('general_symptoms', selectedSymptoms);
                },
                activeColor: Colors.pink.shade400,
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _QuestionPage2 extends StatelessWidget {
  const _QuestionPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentViewModel>(
      builder: (context, viewModel, child) {
        final double energyLevel = viewModel.quizAnswers['energy_level'];

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bagaimana Tingkat Energi Anda?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Skala 1 (sangat lelah) hingga 10 (sangat berenergi).',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '${energyLevel.toInt()}',
                  style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade300),
                ),
              ),
              Slider(
                value: energyLevel,
                min: 1,
                max: 10,
                divisions: 9,
                label: energyLevel.round().toString(),
                onChanged: (double value) {
                  viewModel.updateAnswer('energy_level', value);
                },
                activeColor: Colors.pink.shade400,
                inactiveColor: Colors.pink.shade100,
              ),
              const Spacer(),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}

class _QuestionPage3 extends StatelessWidget {
  const _QuestionPage3({Key? key}) : super(key: key);

  static const Map<String, String> nauseaLevels = {
    'tidak_ada': 'Tidak ada mual',
    'ringan': 'Ringan (kadang-kadang terasa)',
    'sedang': 'Sedang (mengganggu aktivitas)',
    'parah': 'Parah (sulit makan/minum)',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentViewModel>(
      builder: (context, viewModel, child) {
        final String selectedLevel = viewModel.quizAnswers['nausea_severity'];

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Bagaimana Tingkat Mual Anda?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...nauseaLevels.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value, style: const TextStyle(fontSize: 18)),
                value: entry.key,
                groupValue: selectedLevel,
                onChanged: (String? value) {
                  if (value != null) {
                    viewModel.updateAnswer('nausea_severity', value);
                  }
                },
                activeColor: Colors.pink.shade400,
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

class _QuestionPage4 extends StatelessWidget {
  const _QuestionPage4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AssessmentViewModel>(
      builder: (context, viewModel, child) {
        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Apakah Ada Catatan Lain?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jika ada hal lain yang ingin Anda sampaikan, tuliskan di sini.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              maxLines: 5,
              onChanged: (value) {
                viewModel.updateAnswer('additional_notes', value);
              },
              decoration: InputDecoration(
                hintText:
                    'Contoh: Saya merasa lebih sering lapar minggu ini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.pink.shade400, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Center(
              child: Icon(Icons.check_circle_outline,
                  size: 80, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Anda hampir selesai! Tekan tombol "Kirim Asesmen" di bawah untuk melihat laporan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }
}
