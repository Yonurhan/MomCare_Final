// lib/view_models/home_view_model.dart

import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/assessment_service.dart';
import '../models/user_model.dart';
import '../models/nutrition_summary_model.dart';
import '../services/background_service.dart';
import '../screens/assessment_screen.dart';
import '../screens/assessment_result_screen.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;
  final AssessmentService _assessmentService;

  HomeViewModel({
    required AuthService authService,
    required ApiService apiService,
    required AssessmentService assessmentService,
  })  : _authService = authService,
        _apiService = apiService,
        _assessmentService = assessmentService;

  // States
  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;
  NutritionSummary? _nutritionSummary;
  bool _isAssessmentRequired = true;
  bool _isDisposed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  NutritionSummary? get nutritionSummary => _nutritionSummary;
  bool get isAssessmentRequired => _isAssessmentRequired;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> fetchData() async {
    if (!_isLoading) {
      _isLoading = true;
      if (!_isDisposed) notifyListeners();
    }
    _errorMessage = null;

    try {
      final dataFutures = await Future.wait([
        _authService.refreshUserProfile(),
        _apiService.getNutritionSummary(),
        _assessmentService.checkWeeklyAssessmentStatus(),
      ]);

      _currentUser = _authService.currentUser;
      _nutritionSummary = dataFutures[1] as NutritionSummary;

      final statusResult = dataFutures[2] as Map<String, dynamic>;
      _isAssessmentRequired = statusResult['status'] == 'pending';

      _updateNotificationSchedule();
    } catch (e) {
      _errorMessage = "Gagal memuat data: $e";
    } finally {
      _isLoading = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// Mengelola navigasi saat kartu asesmen di-tap
  Future<void> handleAssessmentNavigation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final statusResult =
          await _assessmentService.checkWeeklyAssessmentStatus();
      Navigator.of(context).pop();

      if (statusResult['status'] == 'completed') {
        final int assessmentId = statusResult['assessment_id'];
        _cancelAssessmentReminder();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentResultScreen(assessmentId: assessmentId),
          ),
        );
      } else {
        _scheduleAssessmentReminder();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AssessmentScreen()),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  /// Menjadwalkan atau membatalkan notifikasi berdasarkan state `_isAssessmentRequired`
  void _updateNotificationSchedule() {
    if (_isAssessmentRequired) {
      _scheduleAssessmentReminder();
    } else {
      _cancelAssessmentReminder();
    }
  }

  void _scheduleAssessmentReminder() {
    Workmanager().registerPeriodicTask(
      "assessment-reminder",
      assessmentTask,
      frequency: const Duration(hours: 5),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: const Duration(hours: 5),
    );
    print("Notifikasi pengingat asesmen dijadwalkan.");
  }

  void _cancelAssessmentReminder() {
    Workmanager().cancelByUniqueName("assessment-reminder");
    print("Notifikasi pengingat asesmen dibatalkan.");
  }

  Future<void> logWater() async {
    try {
      await _apiService.logWater();
      if (!_isDisposed) await fetchData();
    } catch (e) {
      print("Error logging water: $e");
    }
  }

  Future<void> logSleep() async {
    try {
      await _apiService.logSleep(hours: 1.0);
      if (!_isDisposed) await fetchData();
    } catch (e) {
      print("Error logging sleep: $e");
    }
  }
}
