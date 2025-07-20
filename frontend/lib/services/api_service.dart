import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- 1. Impor SharedPreferences

// PENTING: Impor model dari file khususnya.
import '../models/chat_models.dart';

class ApiService {
  String get _baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000';

  // --- PERBAIKAN UTAMA ADA DI SINI ---
  // Helper method untuk membuat header otorisasi secara dinamis
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // Pastikan key 'token' sama dengan yang Anda gunakan saat login
    final token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    print("[DEBUG] Request Headers: $headers"); // Untuk debugging
    return headers;
  }

  Future<ChatResponse> sendChatMessage({
    required String message,
    required String userId,
    bool useGemini = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat');
    final headers = await _getHeaders(); // Menggunakan header dengan token
    final body = jsonEncode({
      'message': message,
      'user_id': userId,
      'use_gemini': useGemini,
      'use_openai': !useGemini,
    });

    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        return ChatResponse.fromJson(decodedBody);
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = errorBody['error'] ?? 'Unknown server error';
        throw Exception(
            'Failed to send message: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  Future<ChatHistory> getChatHistory(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/history/$userId');
    final headers = await _getHeaders(); // <-- 2. Dapatkan header dengan token
    print('Fetching chat history from: $uri');

    try {
      // <-- 3. Kirim permintaan dengan header yang sudah ada tokennya
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        return ChatHistory.fromJson(decodedBody);
      } else if (response.statusCode == 404) {
        throw Exception(
            'Riwayat chat tidak ditemukan untuk pengguna ini (404).');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
            'Sesi Anda telah berakhir. Silakan login kembali (401/403).');
      } else {
        print(
            'Failed to load history. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Gagal memuat riwayat: Error ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat riwayat percakapan: ${e.toString()}');
    }
  }
}
