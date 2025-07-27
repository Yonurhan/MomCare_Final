import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart'; 
import 'food_result_screen.dart'; 

class FoodCapture extends StatefulWidget {
  const FoodCapture({Key? key}) : super(key: key);

  @override
  State<FoodCapture> createState() => _FoodCaptureState();
}

class _FoodCaptureState extends State<FoodCapture> {
  final picker = ImagePicker();
  bool _isLoading = false;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) {
      return;
    }
    if (_cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      _processImage(File(imageFile.path));
    } catch (e) {
      print("Error taking picture: $e");
    }
  }

  Future<void> _openGallery() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      _processImage(File(picked.path));
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
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tracker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 20),
                  Text("Analyzing your food...", style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- NEW: Live Camera Preview ---
                Expanded(
                  child: _isCameraInitialized
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: CameraPreview(_cameraController!),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),

                // Bottom controls section
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _openGallery,
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 36),
                      ),
                      GestureDetector(
                        onTap: _takePicture, 
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Center(
                            child: Container(
                              height: 58,
                              width: 58,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 36), 
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}