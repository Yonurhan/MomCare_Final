import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // <-- 1. IMPORT PROVIDER
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:pregnancy_app/services/auth_service.dart'; // <-- 2. IMPORT AUTHSERVICE
import 'package:pregnancy_app/screens/manual_input_screen.dart';
import 'package:pregnancy_app/theme/app_theme.dart';

class FoodResultScreen extends StatefulWidget {
  final File? imageFile;
  final String? dishName;
  final String? imageId;
  final Map<String, dynamic>? nutritionalInfo;

  const FoodResultScreen.imageResult({
    super.key,
    required this.imageFile,
    required this.dishName,
    required this.imageId,
  }) : nutritionalInfo = null;

  const FoodResultScreen.textResult({
    super.key,
    required this.nutritionalInfo,
  })  : imageFile = null,
        dishName = null,
        imageId = null;

  @override
  State<FoodResultScreen> createState() => _FoodResultScreenState();
}

class _FoodResultScreenState extends State<FoodResultScreen> {
  Map<String, dynamic>? _nutritionalInfo;
  bool _isLoading = false;
  bool get _isTextMode => widget.imageFile == null;

  @override
  void initState() {
    super.initState();
    if (_isTextMode) {
      _nutritionalInfo = widget.nutritionalInfo;
    } else {
      if (widget.imageId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchNutritionInfo();
        });
      }
    }
  }

  Future<void> _fetchNutritionInfo() async {
    if (widget.imageId == null || widget.imageId!.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final baseUrl = dotenv.env['BASE_URL'];
      final resp = await http.post(
        Uri.parse('$baseUrl/food_detection/get_nutritional_info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageId': widget.imageId}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _nutritionalInfo = data['nutritional_info'];
        });
      } else {
        throw Exception('Failed to fetch nutrition: ${resp.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 3. THIS IS THE CORRECTED SAVE FUNCTION
  Future<void> _saveNutritionalInfo() async {
    if (_nutritionalInfo == null) return;
    setState(() => _isLoading = true);

    final payload = {
      'calories': _nutritionalInfo!['calories'] ?? 0,
      'protein': _nutritionalInfo!['protein'] ?? 0,
      'fat': _nutritionalInfo!['fat'] ?? 0,
      'carbs': _nutritionalInfo!['carbs'] ?? 0,
    };

    try {
      // Get the token correctly from AuthService using Provider
      final token = Provider.of<AuthService>(context, listen: false).token;
      
      if (token == null) {
        // This is the source of your error
        throw Exception('You are not logged in.');
      }

      final baseUrl = dotenv.env['BASE_URL'];
      final resp = await http.post(
        Uri.parse('$baseUrl/food_detection/store_nutritional_info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Correctly formatted header
        },
        body: jsonEncode(payload),
      );

      final decodedBody = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(backgroundColor: Colors.green, content: Text(decodedBody['message'] ?? 'Successfully saved!')),
        );
        // Navigate back to the home screen after saving
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception(decodedBody['error'] ?? 'Failed to save nutrition data.');
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Save Error: $e')));
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final calories = (_nutritionalInfo?['calories'] as num?)?.toDouble() ?? 0.0;
    final protein = (_nutritionalInfo?['protein'] as num?)?.toDouble() ?? 0.0;
    final carbs = (_nutritionalInfo?['carbs'] as num?)?.toDouble() ?? 0.0;
    final fat = (_nutritionalInfo?['fat'] as num?)?.toDouble() ?? 0.0;
    final totalMacros = protein + carbs + fat;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        title: Text(
          _isTextMode ? 'Manual Entry Result' : 'Nutritional Subject',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          if (_nutritionalInfo != null || !_isTextMode)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isTextMode)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: widget.imageFile != null
                          ? Image.file(
                              widget.imageFile!,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(height: 250, color: Colors.grey[200]),
                    ),
                  if (!_isTextMode) const SizedBox(height: 24),

                  Text(
                    _isTextMode ? 'Total Nutrition' : widget.dishName ?? 'Unknown Food',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${calories.toStringAsFixed(0)} Kcal',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  _buildMacroIndicator('Prot', protein, 'g', totalMacros > 0 ? protein / totalMacros : 0, const Color(0xFF50E486)),
                  const SizedBox(height: 12),
                  _buildMacroIndicator('Carb', carbs, 'g', totalMacros > 0 ? carbs / totalMacros : 0, const Color(0xFF8650E4)),
                  const SizedBox(height: 12),
                  _buildMacroIndicator('Fats', fat, 'g', totalMacros > 0 ? fat / totalMacros : 0, const Color(0xFFE47A50)),
                  const SizedBox(height: 32),
                  
                  if (!_isTextMode)
                    Center(
                      child: TextButton(
                        onPressed: (){
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const ManualInputScreen()),
                          );
                        },
                        child: const Text(
                          'Not your food? Input your food manually',
                           style: TextStyle(color: AppTheme.primaryColor),
                         ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveNutritionalInfo,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroIndicator(String label, double value, String unit, double percentage, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(1)}$unit', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          color: color,
          minHeight: 8,
        ),
      ],
    );
  }
}