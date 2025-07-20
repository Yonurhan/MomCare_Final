import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_models.dart';

class ApiService {
  String get _baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000';

  final Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Future<ChatResponse> sendChatMessage({
    required String message,
    required String userId,
    bool useGemini = true,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chat');
    final body = jsonEncode({
      'message': message,
      'user_id': userId,
      'use_gemini': useGemini,
      'use_openai': !useGemini,
    });

    try {
      final response = await http
          .post(uri, headers: _headers, body: body)
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
    final uri = Uri.parse('$_baseUrl/history/$userId');
    print('Fetching chat history from: $uri');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
        return ChatHistory.fromJson(decodedBody);
      }
      // --- PERUBAHAN UTAMA DI SINI ---
      else if (response.statusCode == 404) {
        // Jangan kembalikan data kosong. Lemparkan error yang jelas.
        throw Exception(
            'Riwayat chat tidak ditemukan untuk pengguna ini (404).');
      } else {
        print(
            'Failed to load history. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Gagal memuat riwayat: Error ${response.statusCode}');
      }
    } catch (e) {
      // Melempar kembali error agar bisa ditangkap oleh FutureBuilder
      throw Exception('Gagal memuat riwayat percakapan: ${e.toString()}');
    }
  }
}
