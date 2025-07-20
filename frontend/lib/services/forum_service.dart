import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/forum_model.dart';
import '../models/comment_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ForumService {
  final baseUrl = dotenv.env['BASE_URL'];
  final Map<String, String> headers;

  ForumService({required this.headers});

  // --- GET ALL FORUMS (DENGAN SEARCH) ---
  Future<ForumResponse> getForums({
    int page = 1,
    int perPage = 10,
    String sortBy = 'created_at',
    String order = 'desc',
    int? userId,
    String? search, // Parameter search ditambahkan
  }) async {
    // Membangun URL dasar
    String url =
        '$baseUrl/api/forums?page=$page&per_page=$perPage&sort_by=$sortBy&order=$order';

    // Menambahkan filter opsional
    if (userId != null) {
      url += '&user_id=$userId';
    }
    if (search != null && search.isNotEmpty) {
      url +=
          '&search=${Uri.encodeComponent(search)}'; // URI Encode untuk keamanan
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return ForumResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load forums');
    }
  }

  Future<Forum> getForumDetails(int forumId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/forums/$forumId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return Forum.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load forum details');
    }
  }

  Future<Forum> createForum({
    required String title,
    required String description,
    File? image,
  }) async {
    if (image != null) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/forums'),
      );
      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
        'Accept': 'application/json',
      });
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Forum.fromJson(data['forum']);
      } else {
        throw Exception('Failed to create forum: ${response.body}');
      }
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/api/forums'),
        headers: headers,
        body: json.encode({
          'title': title,
          'description': description,
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Forum.fromJson(data['forum']);
      } else {
        throw Exception('Failed to create forum');
      }
    }
  }

  Future<void> updateForum({
    required int forumId,
    required String title,
    required String description,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/forums/$forumId'),
      headers: headers,
      body: json.encode({
        'title': title,
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update forum');
    }
  }

  Future<void> deleteForum(int forumId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/forums/$forumId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete forum');
    }
  }

  Future<Comment> addComment(int forumId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/forums/$forumId/comments'),
      headers: headers,
      body: json.encode({'content': content}),
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Comment.fromJson(data['comment']);
    } else {
      throw Exception('Failed to add comment');
    }
  }

  Future<CommentResponse> getComments(int forumId,
      {int page = 1, int perPage = 10}) async {
    final response = await http.get(
      Uri.parse(
          '$baseUrl/api/forums/$forumId/comments?page=$page&per_page=$perPage'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return CommentResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<Map<String, dynamic>> toggleLike(int forumId, bool isLike) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/forums/$forumId/like'),
      headers: headers,
      body: json.encode({'is_like': isLike}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to process like/dislike');
    }
  }

  // --- GET MY FORUMS (DENGAN SEARCH) ---
  Future<ForumResponse> getMyForums({
    int page = 1,
    int perPage = 10,
    String sortBy = 'created_at',
    String order = 'desc',
    String? search, // Parameter search ditambahkan
  }) async {
    // Membangun URL dasar
    String url =
        '$baseUrl/api/forums/me?page=$page&per_page=$perPage&sort_by=$sortBy&order=$order';

    // Menambahkan filter opsional
    if (search != null && search.isNotEmpty) {
      url +=
          '&search=${Uri.encodeComponent(search)}'; // URI Encode untuk keamanan
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return ForumResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load my forums: ${response.body}');
    }
  }
}
