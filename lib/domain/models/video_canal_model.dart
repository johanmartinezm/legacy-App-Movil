import 'content_model.dart';

/// Un video de los canales de YouTube de Legacy Network y LSO.
///
/// Lo sirve el backend en `/api/content/videos`, ya normalizado y cacheado. La
/// app no habla con YouTube: la clave de la API no puede viajar en el binario
/// —los repositorios son públicos— y así la cuota se gasta una vez para todos.
class VideoDeCanal {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;

  /// Nombre del canal. **Es el autor que se muestra**: en un video de YouTube la
  /// firma correcta es el canal, no una persona.
  final String channel;

  final DateTime? publishedAt;

  const VideoDeCanal({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.channel,
    this.publishedAt,
  });

  factory VideoDeCanal.fromJson(Map<String, dynamic> json) {
    return VideoDeCanal(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      channel: json['channel']?.toString() ?? '',
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
    );
  }

  /// Lo convierte al modelo común de la sección de contenido.
  ///
  /// La descripción de YouTube trae saltos de línea, emoji y enlaces sueltos:
  /// para la tarjeta del listado se recorta a una línea, y el texto completo
  /// queda en `fullContent` para la pantalla de detalle.
  ContentItem toContentItem() {
    final resumen = description.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ContentItem(
      id: id,
      title: title,
      type: 'video',
      category: channel,
      isFree: true,
      imageUrl: thumbnailUrl,
      description: resumen.length > 160 ? '${resumen.substring(0, 157)}...' : resumen,
      fullContent: description,
      videoUrl: videoUrl,
      date: publishedAt?.toIso8601String().split('T').first,
      authorName: channel,
    );
  }
}
