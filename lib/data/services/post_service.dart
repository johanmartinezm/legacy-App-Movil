import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_constants.dart';

class PostService {
  final http.Client _client;
  final _storage = const FlutterSecureStorage();

  PostService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({String? token}) async {
    final authToken = token ?? await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };
  }

  Future<Map<String, dynamic>> toggleLike(
    String postId, {
    String? token,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.likePostEndpoint(postId)}',
    );
    final headers = await _getHeaders(token: token);

    try {
      final response = await _client.post(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to toggle like: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> getLikeStatus(
    String postId, {
    String? token,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getLikesEndpoint(postId)}',
    );
    final headers = await _getHeaders(token: token);

    try {
      final response = await _client.get(url, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get like status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<void> recordView(String postId, {String? title, String? token}) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.recordViewEndpoint(postId)}',
    );
    final headers = await _getHeaders(token: token);

    try {
      await _client.post(
        url,
        headers: headers,
        body: jsonEncode({'title': title ?? ''}),
      );
    } catch (e) {
      debugPrint('Error recording view: $e');
    }
  }
}
