import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/models/custom_content_model.dart';
import '../config/api_constants.dart';

class CustomContentService {
  Future<List<CustomContent>> getCustomContents({String? categorySlug}) async {
    try {
      final queryParams = categorySlug != null ? '?category=$categorySlug' : '';
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.contentItemsEndpoint}$queryParams',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CustomContent.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar contenido personalizado');
      }
    } catch (e) {
      print('Error in CustomContentService: $e');
      return [];
    }
  }

  Future<CustomContent?> getCustomContentById(String id) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.contentItemsEndpoint}/$id',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return CustomContent.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Error in CustomContentService: $e');
      return null;
    }
  }
}
