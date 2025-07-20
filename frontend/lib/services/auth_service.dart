import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  static const String baseUrl = 'http://192.168.0.103:5000/api';

  bool _isAuthenticated = false;
  String? _token;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  User? get currentUser => _currentUser;

  AuthService() {
    tryAutoLogin();
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('token')) {
        return false;
      }

      final storedToken = prefs.getString('token');
      final userDataString = prefs.getString('user_data');

      if (storedToken == null || userDataString == null) {
        return false;
      }

      _token = storedToken;
      _currentUser = User.fromJson(jsonDecode(userDataString));
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      print("Failed to auto login: $e");
      await logout();
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        if (data['user'] != null) {
          await prefs.setString('user_data', jsonEncode(data['user']));
        }
        await tryAutoLogin();
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      throw Exception('Error saat login: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    int age,
    int weight,
    int height,
    int trimester,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'age': age,
          'weight': weight,
          'height': height,
          'trimester': trimester,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      throw Exception('Error saat registrasi: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
    await prefs.remove('hasSeenOnboarding');

    _isAuthenticated = false;
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}
