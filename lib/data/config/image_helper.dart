import 'package:flutter/foundation.dart';

import 'api_constants.dart';

/// Helper de imágenes para solucionar problemas de Mixed Content / CORS
/// en Flutter Web cuando se solicitan imágenes alojadas en dominios externos.
class ImageHelper {
  /// Reescribe la URL de la imagen en caso de estar en Web para
  /// que pase por el HAProxy local y evite problemas de CORS.
  /// Convierte una ruta del propio backend (`/api/images/...`, como se guarda
  /// `profile_image_url`) en una URL completa. `NetworkImage` no entiende
  /// rutas relativas: en el teléfono la foto simplemente no salía.
  static String resolverUrl(String url) {
    if (url.startsWith('/')) return '${ApiConstants.baseUrl}$url';
    return getProxiedImageUrl(url);
  }

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
