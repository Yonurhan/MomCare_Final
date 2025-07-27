import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Impor semua model yang dibutuhkan oleh service ini
import '../models/chat_models.dart';
import '../models/nutrition_summary_model.dart';

class ApiService {
  // Properti _baseUrl yang hilang sebelumnya
  String get _baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000';

  // Helper method _getHeaders yang hilang sebelumnya
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- FUNGSI BARU UNTUK NUTRISI ---

  Future<NutritionSummary> getNutritionSummary() async {
    final uri = Uri.parse('$_baseUrl/nutrition/summary');
    final headers = await _getHeaders();
    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return NutritionSummary.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal memuat ringkasan nutrisi: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat mengambil ringkasan nutrisi: $e');
    }
  }

  Future<void> logWater() async {
    final uri = Uri.parse('$_baseUrl/food_detection/log/water');
    final headers = await _getHeaders();
    try {
      final response = await http.post(uri, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Gagal mencatat air: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat mencatat air: $e');
    }
  }

  Future<void> logSleep({required double hours}) async {
    final uri = Uri.parse('$_baseUrl/food_detection/log/sleep');
    final headers = await _getHeaders();
    final body = jsonEncode({'hours': hours});
    try {
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode != 200) {
        throw Exception('Gagal mencatat tidur: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat mencatat tidur: $e');
    }
  }

  // --- FUNGSI LAMA UNTUK CHAT ---

  Future<ChatResponse> sendChatMessage({
    required String message,
    required String userId,
    bool useGemini = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat');
    final headers = await _getHeaders();
    final body = jsonEncode({
      'message': message, 'user_id': userId, 'use_gemini': useGemini, 'use_openai': !useGemini,
    });
    try {
      final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return ChatResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('Gagal mengirim pesan: ${response.statusCode} - ${errorBody['error']}');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<ChatHistory> getChatHistory(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/history/$userId');
    final headers = await _getHeaders();
    try {
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return ChatHistory.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Gagal memuat riwayat: Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat riwayat percakapan: ${e.toString()}');
    }
  }
}