import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/content_model.dart';

class FavoritesProvider extends ChangeNotifier {
  List<ContentItem> _favorites = []; // Initialize as empty list
  bool _isLoading = false;

  List<ContentItem> get favorites => _favorites;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String response = await rootBundle.loadString('assets/data/favorites_data.json');
      final data = await json.decode(response);
      
      if (data['favorites'] != null) {
        _favorites = (data['favorites'] as List)
            .map((e) => ContentItem.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleFavorite(ContentItem item) {
    final index = _favorites.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(item);
    }
    notifyListeners();
  }

  bool isFavorite(String id) {
    return _favorites.any((element) => element.id == id);
  }
}
