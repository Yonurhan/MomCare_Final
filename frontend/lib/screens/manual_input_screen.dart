import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pregnancy_app/screens/food_result_screen.dart';
import 'package:pregnancy_app/theme/app_theme.dart';

class ManualInputScreen extends StatefulWidget {
  const ManualInputScreen({Key? key}) : super(key: key);

  @override
  State<ManualInputScreen> createState() => _ManualInputScreenState();
}

class _ManualInputScreenState extends State<ManualInputScreen> {
  final List<Map<String, TextEditingController>> _controllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with one empty item row
    if (_controllers.isEmpty) {
      _addItem();
    }
  }

  @override
  void dispose() {
    for (var pair in _controllers) {
      pair['name']?.dispose();
      pair['quantity']?.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _controllers.add({
        'name': TextEditingController(),
        'quantity': TextEditingController(),
      });
    });
  }

  void _removeItem(int index) {
    // Prevent removing the last item
    if (_controllers.length > 1) {
      setState(() {
        _controllers[index]['name']?.dispose();
        _controllers[index]['quantity']?.dispose();
        _controllers.removeAt(index);
      });
    }
  }

  Future<void> _submitTextItems() async {
    setState(() => _isLoading = true);

    final items = _controllers
        .map((pair) {
          final name = pair['name']!.text.trim();
          // Assume 'g' for grams if no unit is specified
          final quantity = pair['quantity']!.text.trim();
          return (name.isNotEmpty && quantity.isNotEmpty)
              ? {'name': name, 'quantity': '${quantity}g'} // Send quantity as string with unit
              : null;
        })
        .where((e) => e != null)
        .cast<Map<String, dynamic>>()
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter at least one valid food item.')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final baseUrl = dotenv.env['BASE_URL'];
      final response = await http.post(
        Uri.parse('$baseUrl/food_detection/get_nutrition_by_text'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'items': items}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if(mounted){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FoodResultScreen.textResult(
                nutritionalInfo: data,
              ),
            ),
          );
        }

      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if(mounted){
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      appBar: AppBar(
        title: const Text('Manual Food Entry'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _controllers.length,
                    itemBuilder: (ctx, i) {
                      final pair = _controllers[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: pair['name'],
                                decoration: const InputDecoration(
                                  labelText: 'Food Name (e.g., "Egg")',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: pair['quantity'],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Quantity (g)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItem(i),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Item'),
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black, backgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitTextItems,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Get Nutritional Info'),
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
}