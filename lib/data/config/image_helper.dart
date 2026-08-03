import 'package:flutter/foundation.dart';

/// Helper de imágenes para solucionar problemas de Mixed Content / CORS
/// en Flutter Web cuando se solicitan imágenes alojadas en dominios externos.
class ImageHelper {
  /// Reescribe la URL de la imagen en caso de estar en Web para
  /// que pase por el HAProxy local y evite problemas de CORS.
  static String getProxiedImageUrl(String originalUrl) {
    // Si no estamos en la plataforma web, la URL se mantiene original
    if (!kIsWeb || originalUrl.isEmpty) return originalUrl;

    // Solo reescribimos si es del dominio original problemático (legacynetworkco.com)
    // para evitar problemas de CORS en Flutter Web.
    if (originalUrl.startsWith('https://legacynetworkco.com')) {
      return originalUrl.replaceFirst(
        'https://legacynetworkco.com',
        'https://app.legacynetworkco.com',
      );
    }

    return originalUrl;
  }
}
