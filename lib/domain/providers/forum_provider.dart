import 'package:flutter/material.dart';
import '../../data/services/forum_service.dart';
import '../models/forum_model.dart';
import 'auth_provider.dart';

class ForumProvider with ChangeNotifier {
  final ForumService _forumService;
  final AuthProvider _authProvider;

  List<Forum> _forums = [];
  bool _isLoading = false;
  String? _error;

  ForumProvider(this._authProvider, {ForumService? forumService})
      : _forumService = forumService ?? ForumService();

  List<Forum> get forums => _forums;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadForums() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _authProvider.token;
      if (token == null) throw Exception('No token available');
      
      _forums = await _forumService.getPublicForums(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> proposeForum(String title, String description) async {
    try {
      final token = _authProvider.token;
      if (token == null) throw Exception('No token available');
      
      await _forumService.proposeForum(title, description, token);
      await loadForums();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ForumPost>> loadPosts(String forumId, {int limit = 20, int offset = 0}) async {
    final token = _authProvider.token;
    if (token == null) throw Exception('No token available');
    return await _forumService.getForumPosts(forumId, token, limit: limit, offset: offset);
  }

  Future<ForumPost> publishPost(String forumId, String content, String imageUrl, {String? parentId}) async {
    try {
      final token = _authProvider.token;
      if (token == null) throw Exception('No token available');
      
      final post = await _forumService.publishPost(forumId, content, imageUrl, token, parentId: parentId);
      
      // Update local forum post count
      final forumIndex = _forums.indexWhere((f) => f.id == forumId);
      if (forumIndex != -1) {
        _forums[forumIndex] = _forums[forumIndex].copyWith(
          postCount: _forums[forumIndex].postCount + 1,
        );
        notifyListeners();
      }
      
      return post;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reportPost(String postId, String reason) async {
    final token = _authProvider.token;
    if (token == null) throw Exception('No token available');
    await _forumService.reportPost(postId, reason, token);
  }
}
