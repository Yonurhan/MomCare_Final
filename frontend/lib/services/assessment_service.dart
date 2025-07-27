import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/assessment_result.dart';

class AssessmentService {
  // Mengambil base URL dari file .env
  final String? baseUrl = dotenv.env['BASE_URL'];

  // Menerima headers (termasuk token) dari luar
  final Map<String, String> headers;

  // Constructor untuk menginisialisasi service dengan headers yang diperlukan
  AssessmentService({required this.headers});

  // Fungsi untuk memulai asesmen (POST) dan mendapatkan URL hasil
  Future<Map<String, dynamic>> performAssessment(
      Map<String, dynamic> quizAnswers) async {
    // Memastikan baseUrl tidak null
    if (baseUrl == null) {
      throw Exception('BASE_URL tidak ditemukan di file .env');
    }

    // Membuat salinan headers dan menambahkan Content-Type
    final requestHeaders = Map<String, String>.from(headers)
      ..['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse('$baseUrl/assessment/perform'),
      headers: requestHeaders,
      body: jsonEncode({'quiz_answers': quizAnswers}),
    );

    if (response.statusCode == 202 || response.statusCode == 409) {
      final body = jsonDecode(response.body);
      final url = body['result_url'];
      // Ekstrak ID dari URL
      final assessmentId = int.parse(Uri.parse(url).pathSegments.last);
      return {
        'status': body['status'],
        'assessmentId': assessmentId,
      };
    } else {
      throw Exception('Gagal memulai proses asesmen: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> checkWeeklyAssessmentStatus() async {
    if (baseUrl == null) {
      throw Exception('BASE_URL tidak ditemukan di file .env');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/assessment/status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memeriksa status asesmen: ${response.body}');
    }
  }

  // Fungsi untuk mengambil hasil asesmen (GET)
  // Ini akan melakukan polling karena prosesnya async
  Future<AssessmentResult> getAssessmentResult(int assessmentId) async {
    // Memastikan baseUrl tidak null
    if (baseUrl == null) {
      throw Exception('BASE_URL tidak ditemukan di file .env');
    }

    while (true) {
      final response = await http.get(
        Uri.parse('$baseUrl/assessment/result/$assessmentId'),
        headers: headers, // Menggunakan headers yang di-pass dari constructor
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'completed') {
          return AssessmentResult.fromJson(data);
        } else if (data['status'] == 'processing') {
          // Tunggu 3 detik sebelum mencoba lagi
          await Future.delayed(Duration(seconds: 3));
        } else {
          // status 'failed'
          throw Exception('Proses asesmen gagal di server.');
        }
      } else if (response.statusCode == 202) {
        // Masih diproses, tunggu 3 detik
        await Future.delayed(Duration(seconds: 3));
      } else {
        throw Exception('Gagal mengambil hasil asesmen: ${response.body}');
      }
    }
  }
}
