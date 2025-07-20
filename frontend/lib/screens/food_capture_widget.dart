import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'food_result_screen.dart'; // Ensure this import is correct

class FoodCapture extends StatefulWidget {
  const FoodCapture({Key? key}) : super(key: key);

  @override
  State<FoodCapture> createState() => _FoodCaptureState();
}

class _FoodCaptureState extends State<FoodCapture> {
  final picker = ImagePicker();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Call _openCamera safely after the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openCamera();
      }
    });
  }

  Future<void> _openCamera() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    
    if (picked != null) {
      _processImage(File(picked.path));
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() => _isLoading = true);

    try {
        final bytes = await imageFile.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) {
          throw Exception("Failed to decode image.");
        }

        final compressed = img.encodeJpg(image, quality: 25);
        final baseUrl = dotenv.env['BASE_URL'];
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/food_detection/detect_food'),
        );
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          compressed,
          filename: 'image.jpg',
        ));
        
        final streamed = await request.send();
        final resBody = await streamed.stream.bytesToString();
        final decoded = jsonDecode(resBody) as Map<String, dynamic>;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // Assuming you have these constructors in your FoodResultScreen
              builder: (_) => FoodResultScreen.imageResult( 
                imageFile: imageFile,
                dishName: decoded['dish_name'] ?? 'Unknown',
                imageId: decoded['imageId']?.toString() ?? '',
              ),
            ),
          );
        }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
            );
            Navigator.of(context).pop();
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
      appBar: AppBar(
        title: const Text('Capture Food'),
        automaticallyImplyLeading: false, // Prevents a back arrow
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Analyzing your food..."),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                    SizedBox(height: 20),
                    Text('Opening camera...'),
                ],
            )
      ),
    );
  }
}