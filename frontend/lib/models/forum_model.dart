// lib/models/forum_model.dart
import 'comment_model.dart';

class Forum {
  final int id;
  final String title;
  final String description;
  final String? imagePath;
  final int userId;
  final String username;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final String? userLikeStatus; // 'like', 'dislike', or null
  final List<Comment> comments;

  Forum({
    required this.id,
    required this.title,
    required this.description,
    this.imagePath,
    required this.userId,
    required this.username,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.commentCount = 0,
    this.userLikeStatus,
    this.comments = const [],
  });

  // Metode untuk membuat salinan objek dengan nilai yang diperbarui
  Forum copyWith({
    int? id,
    String? title,
    String? description,
    String? imagePath,
    int? userId,
    String? username,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    int? dislikeCount,
    int? commentCount,
    String? userLikeStatus,
    List<Comment>? comments,
  }) {
    return Forum(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      commentCount: commentCount ?? this.commentCount,
      // Untuk properti nullable, kita bisa langsung menimpanya.
      // Jika userLikeStatus adalah null, nilai baru akan null.
      userLikeStatus: userLikeStatus,
      comments: comments ?? this.comments,
    );
  }

  factory Forum.fromJson(Map<String, dynamic> json) {
    List<Comment> commentsList = [];
    if (json['comments'] != null) {
      commentsList = List<Comment>.from(
        json['comments'].map((comment) => Comment.fromJson(comment)),
      );
    }

    return Forum(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imagePath: json['image_path'],
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      likeCount: json['like_count'] ?? 0,
      dislikeCount: json['dislike_count'] ?? 0,
      commentCount: json['comment_count'] ?? json['comments']?.length ?? 0,
      userLikeStatus: json['user_like_status'],
      comments: commentsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'user_id': userId,
      'username': username,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'like_count': likeCount,
      'dislike_count': dislikeCount,
      'comment_count': commentCount,
      'user_like_status': userLikeStatus,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
}

class ForumResponse {
  final List<Forum> forums;
  final int total;
  final int pages;
  final int currentPage;

  ForumResponse({
    required this.forums,
    required this.total,
    required this.pages,
    required this.currentPage,
  });

  factory ForumResponse.fromJson(Map<String, dynamic> json) {
    return ForumResponse(
      forums: List<Forum>.from(
        json['forums'].map((forum) => Forum.fromJson(forum)),
      ),
      total: json['total'],
      pages: json['pages'],
      currentPage: json['current_page'],
    );
  }
}
