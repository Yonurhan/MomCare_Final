import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';

import '../models/forum_model.dart';
import '../services/forum_service.dart';
import '../services/auth_service.dart';
import '../widgets/forum_card.dart';
import 'forum_detail_screen.dart';
import 'create_forum_screen.dart';
import '../theme/app_theme.dart'; // Pastikan AppTheme ada dan didefinisikan dengan baik

enum ForumViewMode { all, myForums }

class ForumScreen extends StatefulWidget {
  const ForumScreen({Key? key}) : super(key: key);

  @override
  _ForumScreenState createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  bool _isLoading = false;
  List<Forum> _forums = [];
  int _currentPage = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'created_at';
  String _order = 'desc';
  ForumViewMode _viewMode = ForumViewMode.all;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fetchForums(isRefreshing: true));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoading &&
        _hasMore) {
      _fetchForums();
    }
  }

  Future<void> _fetchForums({bool isRefreshing = false}) async {
    if (isRefreshing == false && _isLoading) return;
    if (isRefreshing) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _forums.clear();
      });
    }
    setState(() => _isLoading = true);
    try {
      final forumService = Provider.of<ForumService>(context, listen: false);
      final response = (_viewMode == ForumViewMode.myForums)
          ? await forumService.getMyForums(
              page: _currentPage,
              sortBy: _sortBy,
              order: _order,
              search: _searchQuery)
          : await forumService.getForums(
              page: _currentPage,
              sortBy: _sortBy,
              order: _order,
              search: _searchQuery);
      if (!mounted) return;
      setState(() {
        if (isRefreshing)
          _forums = response.forums;
        else
          _forums.addAll(response.forums);
        _currentPage++;
        _hasMore = _currentPage <= response.pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load forums: ${e.toString()}');
    }
  }

  Future<void> _handleLike(int forumId, bool isLike) async {
    final index = _forums.indexWhere((f) => f.id == forumId);
    if (index == -1) return;
    final oldForum = _forums[index];
    int newLikeCount = oldForum.likeCount;
    int newDislikeCount = oldForum.dislikeCount;
    String? newStatus;
    if (isLike) {
      if (oldForum.userLikeStatus == 'like') {
        newLikeCount--;
        newStatus = null;
      } else {
        newLikeCount++;
        if (oldForum.userLikeStatus == 'dislike') newDislikeCount--;
        newStatus = 'like';
      }
    } else {
      if (oldForum.userLikeStatus == 'dislike') {
        newDislikeCount--;
        newStatus = null;
      } else {
        newDislikeCount++;
        if (oldForum.userLikeStatus == 'like') newLikeCount--;
        newStatus = 'dislike';
      }
    }
    final newForum = oldForum.copyWith(
        likeCount: newLikeCount,
        dislikeCount: newDislikeCount,
        userLikeStatus: newStatus);
    setState(() => _forums[index] = newForum);
    try {
      await Provider.of<ForumService>(context, listen: false)
          .toggleLike(forumId, isLike);
    } catch (e) {
      setState(() => _forums[index] = oldForum);
      _showErrorSnackBar('Failed to process action: $e');
    }
  }

  void _startSearch() => setState(() => _isSearching = true);
  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _fetchForums(isRefreshing: true);
  }

  void _changeSorting(String sortBy, String order) {
    if (_sortBy == sortBy && _order == order) return;
    setState(() {
      _sortBy = sortBy;
      _order = order;
    });
    _fetchForums(isRefreshing: true);
  }

  void _changeViewMode(ForumViewMode newMode) {
    if (_viewMode == newMode) return;
    setState(() => _viewMode = newMode);
    _fetchForums(isRefreshing: true);
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToDetail(int forumId) {
    Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ForumDetailScreen(forumId: forumId)))
        .then((_) => _fetchForums(isRefreshing: true));
  }

  void _navigateToCreate() {
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CreateForumScreen()))
        .then((isSuccess) {
      if (isSuccess == true) _changeViewMode(ForumViewMode.myForums);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = Provider.of<AuthService>(context).isAuthenticated;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () => _fetchForums(isRefreshing: true),
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(isAuthenticated),
            if (isAuthenticated && !_isSearching) _buildSliverFilterHeader(),
            _buildContentBody(isAuthenticated),
          ],
        ),
      ),
      floatingActionButton: (isAuthenticated && !_isSearching)
          ? FloatingActionButton(
              onPressed: _navigateToCreate,
              tooltip: 'Buat Forum',
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      16)), // Slightly more squared off FAB
              elevation: 6,
            )
          : null,
    );
  }

  SliverAppBar _buildSliverAppBar(bool isAuthenticated) {
    return SliverAppBar(
      expandedHeight: 200.0, // Slightly reduced height for minimalist feel
      pinned: true,
      elevation: 0, // No elevation, let the gradient and wave handle depth
      backgroundColor:
          Colors.transparent, // Crucial for showing custom background
      foregroundColor: Colors.white,
      flexibleSpace: Stack(
        children: [
          // Background Gradient (subtler, more soothing)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.95), // Deeper primary
                  AppTheme.primaryColor,
                  const Color.fromARGB(
                      255, 182, 54, 160), // A complementary deeper shade
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0], // More balanced distribution
              ),
              boxShadow: [
                // Add subtle shadow when expanded
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          // Custom Wave/Shape Effect at the bottom (smoother and less sharp)
          Positioned(
            bottom: -1, // Overlap slightly to ensure no gap
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _SubtleWavePainter(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor),
              child: Container(height: 40), // Slightly reduced wave height
            ),
          ),
          // FlexibleSpaceBar for title and potential subtitle
          FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.only(
                left: 24, bottom: 20), // Adjusted for comfort
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isSearching ? 0.0 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _viewMode == ForumViewMode.myForums
                        ? 'Forum Saya'
                        : 'Komunitas',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, // Bolder for clarity
                      fontSize: 24, // Clearer, but not overly large
                      color: Colors.white,
                      letterSpacing: 0.5, // Slight letter spacing for elegance
                    ),
                  ),
                  const SizedBox(height: 6), // Slightly more vertical space
                  if (_viewMode == ForumViewMode.all)
                    Text(
                      'Jelajahi diskusi dan berbagi ide.', // More inviting message
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white
                            .withOpacity(0.85), // Brighter secondary text
                        fontWeight: FontWeight.w300, // Lighter for contrast
                      ),
                    ),
                  if (_viewMode == ForumViewMode.myForums && isAuthenticated)
                    Text(
                      'Lihat dan kelola postingan Anda.', // More concise
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AnimatedCrossFade(
          firstChild: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'Cari topik atau nama pengguna...', // More descriptive hint
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _searchController.clear();
                      setState(
                          () => _searchQuery = ''); // Clear query immediately
                      _fetchForums(isRefreshing: true);
                    } else {
                      _stopSearch(); // Stop search mode if already empty
                    }
                  },
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  // Define enabled border
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2), // Stronger focus indicator
                ),
              ),
              onSubmitted: (query) {
                if (query != _searchQuery) {
                  setState(() => _searchQuery = query);
                  _fetchForums(isRefreshing: true);
                }
              },
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isSearching
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
      ),
      actions: _isSearching
          ? [
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _stopSearch)
            ]
          : [
              IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _startSearch),
              PopupMenuButton<Map<String, String>>(
                icon: const Icon(Icons.sort, color: Colors.white),
                onSelected: (value) =>
                    _changeSorting(value['sortBy']!, value['order']!),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: {'sortBy': 'created_at', 'order': 'desc'},
                    child: Text('Terbaru',
                        style: TextStyle(
                            color: _sortBy == 'created_at' && _order == 'desc'
                                ? AppTheme.primaryColor
                                : AppTheme.primaryTextColor,
                            fontWeight:
                                FontWeight.w500)), // Semi-bold for selected
                  ),
                  PopupMenuItem(
                    value: {'sortBy': 'created_at', 'order': 'asc'},
                    child: Text('Terlama',
                        style: TextStyle(
                            color: _sortBy == 'created_at' && _order == 'asc'
                                ? AppTheme.primaryColor
                                : AppTheme.primaryTextColor,
                            fontWeight: FontWeight.w500)),
                  ),
                  PopupMenuItem(
                    value: {'sortBy': 'like_count', 'order': 'desc'},
                    child: Text('Paling Disukai',
                        style: TextStyle(
                            color: _sortBy == 'like_count' && _order == 'desc'
                                ? AppTheme.primaryColor
                                : AppTheme.primaryTextColor,
                            fontWeight: FontWeight.w500)),
                  ),
                  PopupMenuItem(
                    value: {'sortBy': 'comment_count', 'order': 'desc'},
                    child: Text('Paling Banyak Komentar',
                        style: TextStyle(
                            color:
                                _sortBy == 'comment_count' && _order == 'desc'
                                    ? AppTheme.primaryColor
                                    : AppTheme.primaryTextColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
    );
  }

  SliverPersistentHeader _buildSliverFilterHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterHeaderDelegate(
        onViewModeChanged: _changeViewMode,
        viewMode: _viewMode,
      ),
    );
  }

  Widget _buildContentBody(bool isAuthenticated) {
    if (_isLoading && _forums.isEmpty) {
      return SliverToBoxAdapter(child: _buildShimmerLoading());
    }
    if (_forums.isEmpty && !_isLoading) {
      return SliverFillRemaining(child: _buildEmptyState());
    }
    return _buildForumList(isAuthenticated);
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: 3, // Show a few more shimmer items
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          height: 250, // Adjusted shimmer height for consistency
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined,
              size: 80, color: Colors.grey[300]), // Lighter icon color
          const SizedBox(height: 20), // More space
          Text(
            "Tidak ada postingan forum ditemukan.", // More specific message
            style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
          if (_viewMode == ForumViewMode.myForums) ...[
            const SizedBox(height: 8),
            Text(
              "Mulai buat postingan pertamamu!",
              style: TextStyle(
                  fontSize: 15, color: Colors.grey[500]), // Slightly larger
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Optional: Add a button to create a forum directly
            if (Provider.of<AuthService>(context).isAuthenticated)
              ElevatedButton.icon(
                onPressed: _navigateToCreate,
                icon:
                    const Icon(Icons.add_comment_outlined, color: Colors.white),
                label: const Text('Buat Postingan Baru',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildForumList(bool isAuthenticated) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= _forums.length) {
            return _hasMore
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : const SizedBox(height: 32);
          }
          final forum = _forums[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 70.0,
              child: FadeInAnimation(
                child: ForumCard(
                  forum: forum,
                  getFullImageUrl: _getFullImageUrl,
                  onTap: () => _navigateToDetail(forum.id),
                  onLike: isAuthenticated
                      ? () => _handleLike(forum.id, true)
                      : null,
                  onDislike: isAuthenticated
                      ? () => _handleLike(forum.id, false)
                      : null,
                ),
              ),
            ),
          );
        },
        childCount: _forums.length + (_hasMore ? 1 : 0),
      ),
    );
  }
}

// Delegate untuk filter header yang menempel
class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ForumViewMode viewMode;
  final ValueChanged<ForumViewMode> onViewModeChanged;

  _FilterHeaderDelegate(
      {required this.viewMode, required this.onViewModeChanged});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Slight shadow to differentiate from content below when pinned
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          if (shrinkOffset > 0) // Only show shadow when scrolled
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            _filterChip(
                label: 'Semua Diskusi', // More descriptive label
                isSelected: viewMode == ForumViewMode.all,
                onTap: () => onViewModeChanged(ForumViewMode.all)),
            const SizedBox(width: 10),
            _filterChip(
                label: 'Postingan Saya',
                isSelected: viewMode == ForumViewMode.myForums,
                onTap: () => onViewModeChanged(ForumViewMode.myForums)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
      {required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onTap(),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primaryTextColor,
          fontWeight: isSelected
              ? FontWeight.bold
              : FontWeight.normal), // Bold only when selected
      backgroundColor: Colors.grey[100], // Lighter background for unselected
      shape: RoundedRectangleBorder(
        // RoundedRect border for a softer look
        borderRadius: BorderRadius.circular(20),
        side: isSelected
            ? BorderSide.none
            : BorderSide(color: Colors.grey[300]!), // Subtle border
      ),
      showCheckmark: false,
      elevation: isSelected ? 3 : 0, // Elevation only when selected
      pressElevation: 6,
    );
  }

  @override
  double get maxExtent => 60.0;
  @override
  double get minExtent => 60.0;
  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) =>
      oldDelegate.viewMode != viewMode;
}

// Custom Painter for a more subtle wave effect
class _SubtleWavePainter extends CustomPainter {
  final Color backgroundColor;

  _SubtleWavePainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = backgroundColor;
    final path = Path();

    // Start from bottom-left
    path.lineTo(0, size.height * 0.8);

    // First curve: gentle dip
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.6,
        size.width * 0.5, size.height * 0.8);

    // Second curve: gentle rise
    path.quadraticBezierTo(
        size.width * 0.75, size.height, size.width, size.height * 0.8);

    // Close the path to form a filled shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SubtleWavePainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor;
}
