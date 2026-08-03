import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/banner_model.dart';
import '../../data/config/api_constants.dart';
import '../../data/config/image_helper.dart';

class BannerProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  List<BannerModel> _homeBanners = [];
  List<BannerModel> _communityBanners = [];
  bool _isLoading = false;
  final _cacheCompleter = Completer<void>();

  List<BannerModel> get homeBanners => _homeBanners;
  List<BannerModel> get communityBanners => _communityBanners;
  bool get isLoading => _isLoading;

  BannerProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadFromCache();
    if (!_cacheCompleter.isCompleted) _cacheCompleter.complete();
  }

  Future<void> _loadFromCache() async {
    try {
      final homeCache = await _storage.read(key: 'banners_home');
      final communityCache = await _storage.read(key: 'banners_community');

      if (homeCache != null) {
        final List<dynamic> data = json.decode(homeCache);
        _homeBanners = data.map((b) => BannerModel.fromJson(b)).toList();
      }
      if (communityCache != null) {
        final List<dynamic> data = json.decode(communityCache);
        _communityBanners = data.map((b) => BannerModel.fromJson(b)).toList();
      }
      if (homeCache != null || communityCache != null) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading banners from cache: $e');
    }
  }

  Future<void> _saveToCache(String category, List<BannerModel> banners) async {
    try {
      final jsonData = json.encode(banners.map((b) => b.toJson()).toList());
      await _storage.write(key: 'banners_$category', value: jsonData);
    } catch (e) {
      debugPrint('Error saving banners to cache: $e');
    }
  }

  String? _token;

  void updateToken(String? token) {
    if (_token != token) {
      _token = token;
    }
  }

  Future<void> precacheAllBanners(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Cargar datos de ambas categorías en paralelo
      await Future.wait([loadBanners('home'), loadBanners('community')]);

      if (!context.mounted) return;

      // Precargar imágenes de red en memoria
      final allBanners = [..._homeBanners, ..._communityBanners];
      final List<Future<void>> imageFutures = [];

      for (final banner in allBanners) {
        imageFutures.add(
          precacheImage(
            CachedNetworkImageProvider(
                ImageHelper.getProxiedImageUrl(banner.imageUrl)),
            context,
          ),
        );
      }

      await Future.wait(imageFutures);
    } catch (e) {
      debugPrint('Error in global precache: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBanners(String category) async {
    // Esperar a que el caché termine de cargar antes de decidir si mostrar skeleton
    if (!_cacheCompleter.isCompleted) await _cacheCompleter.future;

    final hasData = category == 'home'
        ? _homeBanners.isNotEmpty
        : _communityBanners.isNotEmpty;

    // Solo mostramos loading si NO hay datos en caché
    if (!hasData) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/api/banners?category=$category',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<BannerModel> banners = data
            .map((b) => BannerModel.fromJson(b))
            .toList();

        if (category == 'home') {
          _homeBanners = banners;
        } else {
          _communityBanners = banners;
        }

        await _saveToCache(category, banners);
      }
    } catch (e) {
      debugPrint('Error loading banners ($category): $e');
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      } else {
        // Si no estábamos en loading, igual notificamos que llegaron datos nuevos si es necesario
        notifyListeners();
      }
    }
  }
}
