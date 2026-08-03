import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/synergy_model.dart';
import '../config/api_constants.dart';

class SynergyService {
  final http.Client _client;

  SynergyService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Synergy>> getSynergies({String? category, String? status, String? search, int page = 1}) async {
    try {
      final queryParams = [
        if (category != null && category != 'Todas') 'category=$category',
        if (status != null) 'status=$status',
        if (search != null && search.isNotEmpty) 'search=$search',
        'page=$page',
        'pageSize=20',
      ].join('&');

      final url = Uri.parse('${ApiConstants.baseUrl}/api/synergies?$queryParams');
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Synergy.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar sinergias');
      }
    } catch (e) {
      print('Error in SynergyService.getSynergies: $e');
      return [];
    }
  }

  Future<Synergy?> getSynergyById(String id, String? token) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/synergies/$id');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer ${token.trim()}',
      };
      
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        return Synergy.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      print('Error in SynergyService.getSynergyById: $e');
      return null;
    }
  }

  Future<Synergy?> proposeSynergy(String token, String title, String description, String category, String? imageUrl) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/synergies');
      final body = {
        'title': title,
        'description': description,
        'category': category,
        'image_url': imageUrl,
      };

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.trim()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return Synergy.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Error al proponer sinergia (${response.statusCode}): ${response.body}');
    } catch (e) {
      print('Error in SynergyService.proposeSynergy: $e');
      rethrow;
    }
  }

  Future<SynergyComment?> commentSynergy(String token, String synergyId, String content) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/synergies/$synergyId/comments');
      final body = {'content': content};

      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.trim()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return SynergyComment.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
      throw Exception('Error al comentar');
    } catch (e) {
      print('Error in SynergyService.commentSynergy: $e');
      rethrow;
    }
  }

  Future<bool> toggleLike(String token, String synergyId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/synergies/$synergyId/like');
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.trim()}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['liked'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error in SynergyService.toggleLike: $e');
      return false;
    }
  }
}
