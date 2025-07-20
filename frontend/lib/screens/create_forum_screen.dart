import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import '../services/api_service.dart'; // Pastikan ini relevan atau hapus jika tidak digunakan
import '../services/forum_service.dart';
import '../theme/app_theme.dart'; // Pastikan AppTheme didefinisikan dengan baik

class CreateForumScreen extends StatefulWidget {
  const CreateForumScreen({Key? key}) : super(key: key);

  @override
  _CreateForumScreenState createState() => _CreateForumScreenState();
}

class _CreateForumScreenState extends State<CreateForumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _createForum() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Harap lengkapi semua bidang yang wajib diisi.',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final forumService = Provider.of<ForumService>(context, listen: false);
      await forumService.createForum(
        title: _titleController.text,
        description: _descriptionController.text,
        image: _imageFile,
      );

      if (mounted) {
        Navigator.pop(context, true); // Pass true to indicate success
        _showSnackBar('Forum berhasil dibuat!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal membuat forum: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
            100.0), // Increased height for the custom shape
        child: AppBar(
          backgroundColor: Colors.transparent, // Make AppBar transparent
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(
                left: 8.0, top: 10.0), // Adjust padding for back button
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          flexibleSpace: ClipPath(
            clipper: _AppBarClipper(), // Custom clipper for the AppBar shape
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.95), // Deeper primary
                    AppTheme.primaryColor,
                    const Color(0xFF7B1FA2), // Deeper complementary shade
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: 20.0,
                      top: 20.0), // Adjust padding for title position
                  child: Text(
                    'Buat Postingan Baru',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22, // Larger font size for prominence
                      letterSpacing: 1.0, // Slight letter spacing
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Input
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.primaryTextColor),
                decoration: _inputDecoration(
                  labelText: 'Judul Postingan',
                  hintText: 'Misalnya: Resep Sehat untuk Anak Kos',
                  prefixIcon: Icons.title_rounded,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  if (value.length < 5) {
                    return 'Judul minimal 5 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppTheme.primaryTextColor),
                decoration: _inputDecoration(
                  labelText: 'Deskripsi',
                  hintText:
                      'Tuliskan deskripsi lengkap postingan Anda di sini...',
                  prefixIcon: Icons.description_rounded,
                  alignLabelWithHint: true,
                ),
                maxLines: 7,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  if (value.length < 10) {
                    return 'Deskripsi minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Image Upload Section
              Text(
                'Tambahkan Gambar (Opsional)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _imageFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_rounded,
                              size: 60,
                              color: AppTheme.primaryColor.withOpacity(0.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ketuk untuk mengunggah gambar',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '(Maks. 5MB, JPG/PNG)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),

              // Create Forum Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createForum,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 5,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Buat Postingan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon:
          Icon(prefixIcon, color: AppTheme.primaryColor.withOpacity(0.7)),
      labelStyle: const TextStyle(color: AppTheme.secondaryTextColor),
      hintStyle: TextStyle(color: Colors.grey[400]),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.accentColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: Color.fromARGB(255, 211, 62, 62), width: 2.5),
      ),
    );
  }
}

// Custom Clipper for the AppBar shape
class _AppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30); // Start from bottom-left, slightly up
    path.quadraticBezierTo(
      size.width / 2, size.height, // Control point at bottom center
      size.width, size.height - 30, // End at bottom-right, slightly up
    );
    path.lineTo(size.width, 0); // Line to top-right
    path.close(); // Close the path to top-left
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
