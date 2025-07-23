import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // FIX: Pastikan import ini ada untuk File
import 'package:image_picker/image_picker.dart'; // FIX: Pastikan import ini ada untuk ImagePicker dan XFile
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../models/forum_model.dart';
import '../services/forum_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_bar_clipper.dart'; // FIX: Import AppBarClipper dari file terpisah
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditForumScreen extends StatefulWidget {
  final Forum forum;

  const EditForumScreen({Key? key, required this.forum}) : super(key: key);

  @override
  _EditForumScreenState createState() => _EditForumScreenState();
}

class _EditForumScreenState extends State<EditForumScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  File? _newImageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String? _currentImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.forum.title);
    _descriptionController =
        TextEditingController(text: widget.forum.description);
    _currentImagePath = widget.forum.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null) return '';
    if (imagePath.startsWith('http')) return imagePath;
    final baseUrl = dotenv.env['BASE_URL'];
    if (imagePath.startsWith('/static')) {
      return '$baseUrl$imagePath';
    }
    return '$baseUrl/static/uploads/$imagePath';
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
                      _newImageFile = File(pickedFile.path);
                      _currentImagePath = null;
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
                      _newImageFile = File(pickedFile.path);
                      _currentImagePath = null;
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
      _newImageFile = null;
      _currentImagePath = null;
    });
  }

  Future<void> _updateForum() async {
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
      // FIX: Hapus parameter 'image' dari pemanggilan jika ForumService tidak mendukungnya
      await forumService.updateForum(
        forumId: widget.forum.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        // image: _newImageFile, // HAPUS PARAMETER INI jika ForumService tidak punya
      );

      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar('Forum berhasil diperbarui!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Gagal memperbarui forum: ${e.toString()}',
            isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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
        preferredSize: const Size.fromHeight(100.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 10.0),
            child: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          flexibleSpace: ClipPath(
            clipper:
                AppBarClipper(), // FIX: Menggunakan AppBarClipper dari file terpisah
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.95),
                    AppTheme.primaryColor,
                    const Color(0xFF7B1FA2),
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
                  padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                  child: Text(
                    'Edit Postingan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      'Ubah Gambar (Opsional)',
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
                          border:
                              Border.all(color: AppTheme.accentColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _newImageFile != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      _newImageFile!,
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
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : (_currentImagePath != null &&
                                    _currentImagePath!.isNotEmpty)
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: CachedNetworkImage(
                                          imageUrl: _getFullImageUrl(
                                              _currentImagePath),
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                            baseColor: Colors.grey[200]!,
                                            highlightColor: Colors.white,
                                            child: Container(
                                                height: 200,
                                                color: Colors.grey[200]),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            height: 150,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: Colors.grey[400],
                                                  size: 40),
                                            ),
                                          ),
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
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                            child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.white,
                                                size: 20),
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
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.7),
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
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateForum,
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
                            : const Text('Perbarui Postingan'),
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
