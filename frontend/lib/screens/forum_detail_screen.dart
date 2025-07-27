import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/forum_model.dart';
import '../models/comment_model.dart';
import '../services/auth_service.dart';
import '../services/forum_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_bar_clipper.dart';
import 'edit_forum_screen.dart';

class ForumDetailScreen extends StatefulWidget {
  final int forumId;

  const ForumDetailScreen({
    Key? key,
    required this.forumId,
  }) : super(key: key);

  @override
  _ForumDetailScreenState createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  bool _isLoading = true;
  Forum? _forum;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForumDetails();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
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

  Future<void> _loadForumDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final forumService = Provider.of<ForumService>(context, listen: false);
      final forum = await forumService.getForumDetails(widget.forumId);

      setState(() {
        _forum = forum;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Gagal memuat detail forum: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      _showSnackBar('Komentar tidak boleh kosong.', isError: true);
      return;
    }

    if (!Provider.of<AuthService>(context, listen: false).isAuthenticated) {
      _showSnackBar('Anda harus login untuk berkomentar.', isError: true);
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final forumService = Provider.of<ForumService>(context, listen: false);
      await forumService.addComment(widget.forumId, commentText);

      _commentController.clear();
      FocusScope.of(context).unfocus();
      await _loadForumDetails();
      if (mounted) {
        _showSnackBar('Komentar berhasil ditambahkan.', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menambahkan komentar: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _toggleLike(bool isLike) async {
    if (!Provider.of<AuthService>(context, listen: false).isAuthenticated) {
      _showSnackBar('Anda harus login untuk memberi reaksi.', isError: true);
      return;
    }
    try {
      final forumService = Provider.of<ForumService>(context, listen: false);
      await forumService.toggleLike(widget.forumId, isLike);
      await _loadForumDetails();
    } catch (e) {
      if (mounted) {
        _showSnackBar('Terjadi kesalahan saat memberi reaksi: $e',
            isError: true);
      }
    }
  }

  Future<void> _deleteForum() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Hapus Forum?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Apakah Anda yakin ingin menghapus postingan forum ini? Aksi ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.secondaryTextColor),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 3,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final forumService = Provider.of<ForumService>(context, listen: false);
        await forumService.deleteForum(widget.forumId);
        if (mounted) {
          Navigator.pop(context,
              true); // Kembali ke layar sebelumnya dan beri tahu berhasil
          _showSnackBar('Forum berhasil dihapus.', isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Gagal menghapus forum: ${e.toString()}',
              isError: true);
        }
      }
    }
  }

  void _navigateToEditScreen() {
    if (_forum == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditForumScreen(forum: _forum!),
      ),
    ).then((result) {
      if (result == true) {
        _loadForumDetails();
      }
    });
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
    final authService = Provider.of<AuthService>(context);
    final isAuthenticated = authService.isAuthenticated;
    final currentUser = authService.currentUser;
    final isOwner = _forum != null &&
        currentUser != null &&
        _forum!.userId == currentUser.id;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF0F2F5), // Latar belakang putih keabuan sangat terang
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
                AppBarClipper(), // Menggunakan AppBarClipper dari file terpisah
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
                    'Detail Postingan',
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
          actions: [
            if (isOwner)
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 10.0),
                child: PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _navigateToEditScreen();
                    } else if (value == 'delete') {
                      _deleteForum();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded,
                              color: AppTheme.primaryTextColor),
                          SizedBox(width: 8),
                          Text('Edit Postingan'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus Postingan',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _forum == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Forum tidak ditemukan.',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0,
                            0), // Padding bawah dihilangkan/dikurangi untuk scrollview
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kartu konten forum utama
                            _buildForumContentCard(),
                            const SizedBox(
                                height: 24), // Spasi setelah card postingan

                            // Judul bagian komentar
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 4.0,
                                  bottom: 8.0), // Padding untuk judul komentar
                              child: Text(
                                'Komentar (${_forum!.comments.length})',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppTheme.primaryTextColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          20, // Ukuran font judul komentar
                                    ),
                              ),
                            ),
                            // Divider di sini dihilangkan karena CommentCard akan punya dekorasi sendiri/padding
                            // const Divider(height: 20, thickness: 1, color: Colors.grey),
                            // const SizedBox(height: 8),

                            // Daftar komentar
                            if (_forum!.comments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'Belum ada komentar. Jadilah yang pertama!',
                                    style: TextStyle(
                                        color: AppTheme.secondaryTextColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                // Menggunakan ListView.builder tanpa separatorBuilder untuk spasi via margin di CommentCard
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _forum!.comments.length,
                                itemBuilder: (context, index) {
                                  final comment = _forum!.comments[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom:
                                            12.0), // Spasi antar CommentCard
                                    child: CommentCard(
                                      comment: comment,
                                      currentUserId: currentUser?.id,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Bagian input komentar (hanya jika sudah login)
                    if (isAuthenticated) _buildCommentInputSection(),
                  ],
                ),
    );
  }

  Widget _buildForumContentCard() {
    final bool isLiked = _forum!.userLikeStatus == 'like';
    final bool isDisliked = _forum!.userLikeStatus == 'dislike';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3, // Mengurangi elevation untuk tampilan lebih minimalist
      color: Colors.white, // Pastikan warna card putih
      shadowColor: Colors.grey.withOpacity(0.2), // Warna shadow lebih halus
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Pengguna
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    _forum!.username.isNotEmpty
                        ? _forum!.username[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 22,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Menggunakan Expanded agar Column tidak overflow
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _forum!.username,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppTheme.primaryTextColor),
                        overflow: TextOverflow
                            .ellipsis, // Tambah ellipsis jika nama terlalu panjang
                      ),
                      Text(
                        timeago.format(_forum!.createdAt, locale: 'id'),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Judul Forum
            Text(
              _forum!.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: AppTheme.primaryTextColor,
                  ),
            ),
            const SizedBox(height: 12),

            // Deskripsi Forum
            Text(
              _forum!.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: AppTheme.secondaryTextColor,
                  ),
            ),
            // Gambar Forum (jika ada)
            if (_forum!.imagePath != null &&
                _getFullImageUrl(_forum!.imagePath!).isNotEmpty) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _getFullImageUrl(_forum!.imagePath),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[200]!,
                      highlightColor: Colors.white,
                      child: Container(height: 200, color: Colors.grey[200])),
                  errorWidget: (context, url, error) => Container(
                      height: 150,
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.grey[400], size: 40))),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Mengganti Divider dengan spasi dan padding vertikal lebih halus untuk aksi
            // const Divider(height: 1, thickness: 0.5),

            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0), // Padding vertikal untuk Row aksi
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: isLiked
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined,
                    label: _forum!.likeCount.toString(),
                    color: isLiked
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryTextColor,
                    onTap: () => _toggleLike(true),
                  ),
                  _buildActionButton(
                    icon: isDisliked
                        ? Icons.thumb_down_alt_rounded
                        : Icons.thumb_down_alt_outlined,
                    label: _forum!.dislikeCount.toString(),
                    color: isDisliked
                        ? Colors.blueGrey
                        : AppTheme.secondaryTextColor,
                    onTap: () => _toggleLike(false),
                  ),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: _forum!.commentCount.toString(),
                    color: AppTheme.secondaryTextColor,
                    onTap: null, // Hanya display, tidak ada aksi klik
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        // Bayangan lebih lembut
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Opacity lebih rendah
            blurRadius: 10, // Blur lebih besar
            offset: const Offset(0, -5), // Offset lebih kecil
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Tulis komentar Anda...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 10),
          _isSubmittingComment
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryColor),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _submitComment,
                    tooltip: 'Kirim Komentar',
                  ),
                ),
        ],
      ),
    );
  }
}

// CommentCard (Final tanpa onDelete dan styling baru)
class CommentCard extends StatelessWidget {
  final Comment comment;
  final int? currentUserId;

  const CommentCard({
    Key? key,
    required this.comment,
    this.currentUserId,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return timeago.format(date, locale: 'id');
  }

  @override
  Widget build(BuildContext context) {
    // `isOwner` bisa digunakan untuk styling jika komentar milik user sendiri
    // final isOwner = currentUserId != null && comment.userId == currentUserId;

    return Container(
      // Mengganti Card dengan Container untuk kontrol dekorasi yang lebih halus
      padding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 12.0), // Padding internal
      decoration: BoxDecoration(
        color: Colors.white, // Warna latar belakang komentar
        borderRadius: BorderRadius.circular(16), // Sudut lebih membulat
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08), // Shadow yang sangat halus
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Vertically center align
            children: [
              CircleAvatar(
                radius: 18, // Ukuran avatar lebih kecil
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  comment.username.isNotEmpty
                      ? comment.username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(
                left:
                    46.0), // Menyesuaikan padding agar sejajar dengan teks nama
            child: Text(
              comment.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme
                        .secondaryTextColor, // Warna teks komentar lebih lembut
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
