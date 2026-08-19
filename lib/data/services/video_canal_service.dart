import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/models/video_canal_model.dart';
import '../config/api_constants.dart';

/// Videos de los canales de YouTube, servidos por el backend.
class VideoCanalService {
  /// Devuelve los videos, del más reciente al más antiguo.
  ///
  /// **Nunca lanza.** La sección de contenido une esta fuente con otras dos y
  /// no puede quedarse en blanco porque YouTube esté caído o la cuota agotada;
  /// el backend ya devuelve lista vacía en ese caso, y aquí se cubre además el
  /// fallo de red.
  Future<List<VideoDeCanal>> getVideos() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.contentVideosEndpoint}',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body);
      return data.map((j) => VideoDeCanal.fromJson(j)).toList();
    } catch (e) {
      debugPrint('Error in VideoCanalService: $e');
      return [];
    }
  }
}
