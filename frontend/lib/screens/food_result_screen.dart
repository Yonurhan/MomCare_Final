import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:pregnancy_app/services/auth_service.dart';
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
        throw Exception('Gagal mengambil nutrisi: ${resp.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error: $e')));
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNutritionalInfo() async {
    if (_nutritionalInfo == null) return;
    setState(() => _isLoading = true);

    final payload = {
      'calories': _nutritionalInfo!['calories'] ?? 0,
      'protein': _nutritionalInfo!['protein'] ?? 0,
      'fat': _nutritionalInfo!['fat'] ?? 0,
      'carbs': _nutritionalInfo!['carbs'] ?? 0,
      'folic_acid': _nutritionalInfo!['folic_acid'] ?? 0,
      'iron': _nutritionalInfo!['iron'] ?? 0,
      'calcium': _nutritionalInfo!['calcium'] ?? 0,
      'zinc': _nutritionalInfo!['zinc'] ?? 0,
    };

    try {
      final token = Provider.of<AuthService>(context, listen: false).token;
      if (token == null) {
        throw Exception('Anda tidak sedang login.');
      }

      final baseUrl = dotenv.env['BASE_URL'];
      final resp = await http.post(
        Uri.parse('$baseUrl/food_detection/store_nutritional_info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload), 
      );

      final decodedBody = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.green, content: Text(decodedBody['message'] ?? 'Berhasil disimpan!')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception(decodedBody['error'] ?? 'Gagal menyimpan data nutrisi.');
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Error saat menyimpan: $e')));
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
          _isTextMode ? 'Hasil Input Manual' : 'Informasi Nutrisi',
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          if (_isLoading && _nutritionalInfo == null)
            const Center(child: CircularProgressIndicator())
          else if (_nutritionalInfo != null)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isTextMode && widget.imageFile != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        widget.imageFile!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (!_isTextMode) const SizedBox(height: 24),
                  Text(
                    _isTextMode ? 'Total Nutrisi' : widget.dishName ?? 'Makanan Tidak Dikenal',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${calories.toStringAsFixed(0)} Kkal',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  _buildMacroIndicator('Protein', protein, 'g', totalMacros > 0 ? protein / totalMacros : 0, const Color(0xFF50E486)),
                  const SizedBox(height: 12),
                  _buildMacroIndicator('Karbohidrat', carbs, 'g', totalMacros > 0 ? carbs / totalMacros : 0, const Color(0xFF8650E4)),
                  const SizedBox(height: 12),
                  _buildMacroIndicator('Lemak', fat, 'g', totalMacros > 0 ? fat / totalMacros : 0, const Color(0xFFE47A50)),
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
                          'Bukan makanan Anda? Input manual',
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
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveNutritionalInfo,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_isLoading && _nutritionalInfo != null)
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