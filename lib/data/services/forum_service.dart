import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/forum_model.dart';
import '../config/api_constants.dart';

class ForumService {
  final http.Client _client;

  ForumService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Forum>> getPublicForums(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/api/forums'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) return [];
      return (data as List).map((json) => Forum.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load forums');
    }
  }

  Future<Forum> proposeForum(String title, String description, String token) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/api/forums'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Forum.fromJson(json.decode(response.body));
    } else if (response.statusCode == 422) {
      throw Exception('alias_required');
    } else {
      throw Exception('Failed to propose forum');
    }
  }

  Future<List<ForumPost>> getForumPosts(String forumId, String token, {int limit = 20, int offset = 0}) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/api/forums/$forumId/posts?limit=$limit&offset=$offset'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data == null) return [];
      return (data as List).map((json) => ForumPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  Future<ForumPost> publishPost(String forumId, String content, String imageUrl, String token, {String? parentId}) async {
    final body = <String, dynamic>{
      'content': content,
      'image_url': imageUrl,
    };
    if (parentId != null) {
      body['parent_id'] = parentId;
    }

    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/api/forums/$forumId/posts'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      return ForumPost.fromJson(json.decode(response.body));
    } else if (response.statusCode == 422) {
      throw Exception('alias_required');
    } else {
      throw Exception('Failed to publish post');
    }
  }

  Future<void> reportPost(String postId, String reason, String token) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/api/forums/posts/$postId/report'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'reason': reason}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to report post');
    }
  }
}
