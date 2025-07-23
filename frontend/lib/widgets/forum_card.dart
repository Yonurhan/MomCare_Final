import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/forum_model.dart';
import '../theme/app_theme.dart';

class ForumCard extends StatefulWidget {
  final Forum forum;
  final String Function(String?) getFullImageUrl;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const ForumCard({
    Key? key,
    required this.forum,
    required this.getFullImageUrl,
    required this.onTap,
    this.onLike,
    this.onDislike,
  }) : super(key: key);

  @override
  _ForumCardState createState() => _ForumCardState();
}

class _ForumCardState extends State<ForumCard> {
  bool _isExpanded = false;
  final int _maxLinesCollapsed = 3;

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('id', timeago.IdMessages());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildContent(context),
              _buildImageSection(context),
              const Divider(
                  height: 1, thickness: 0.5, indent: 16, endIndent: 16),
              _buildActionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24, // Slightly larger for better visual
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            widget.forum.username.isNotEmpty
                ? widget.forum.username[0].toUpperCase()
                : 'U',
            style: const TextStyle(
                fontSize: 22,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          widget.forum.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17, // Slightly larger font size
            color: AppTheme.primaryTextColor,
          ),
        ),
        subtitle: Text(
          timeago.format(widget.forum.createdAt, locale: 'id'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 13, color: Colors.grey[600]), // Clearer subtitle
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert_rounded,
              color: Colors.grey[500], size: 24), // More prominent icon
          onPressed: () {
            // TODO: Implement more options like report, share, etc.
          },
        ),
        contentPadding: EdgeInsets.zero, // Remove default padding
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    bool hasMoreText =
        widget.forum.description.split('\n').length > _maxLinesCollapsed ||
            widget.forum.description.length > 150;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.forum.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 19), // Slightly larger title
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            widget.forum.description,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            maxLines: _isExpanded ? 100 : _maxLinesCollapsed,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasMoreText)
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  _isExpanded ? 'Sembunyikan' : 'Lihat selengkapnya...',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final imageUrl = widget.getFullImageUrl(widget.forum.imagePath);
    if (imageUrl.isEmpty) return const SizedBox(height: 8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
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
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final bool isLiked = widget.forum.userLikeStatus == 'like';
    final bool isDisliked = widget.forum.userLikeStatus == 'dislike';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _actionButton(context,
                  icon: isLiked
                      ? Icons.thumb_up_alt_rounded // Filled icon when liked
                      : Icons
                          .thumb_up_alt_outlined, // Outlined icon when not liked
                  label: widget.forum.likeCount.toString(),
                  color: isLiked
                      ? AppTheme.primaryColor
                      : AppTheme.secondaryTextColor,
                  onTap: widget.onLike),
              _actionButton(context,
                  icon: isDisliked
                      ? Icons
                          .thumb_down_alt_rounded // Filled icon when disliked
                      : Icons
                          .thumb_down_alt_outlined, // Outlined icon when not disliked
                  label: widget.forum.dislikeCount.toString(),
                  color: isDisliked
                      ? Colors.blueGrey
                      : AppTheme.secondaryTextColor,
                  onTap: widget.onDislike),
            ],
          ),
          _actionButton(context,
              icon: Icons.chat_bubble_outline_rounded,
              label: widget.forum.commentCount.toString(),
              color: AppTheme.secondaryTextColor,
              onTap: widget.onTap),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      VoidCallback? onTap}) {
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
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
