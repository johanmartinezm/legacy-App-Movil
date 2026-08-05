/// Encuesta general de un evento: una sola respuesta por persona y evento.
///
/// No confundir con la calificación por charla (`WorkshopRating`,
/// `POST /api/workshops/{id}/rating`), que se puede enviar por cada taller.
class EventSurveyModel {
  final String id;
  final String eventId;
  final int overallRating;
  final int? organizationRating;
  final int? contentRating;
  final int? speakersRating;
  final bool? wouldRecommend;
  final String? comment;
  final DateTime? createdAt;

  const EventSurveyModel({
    required this.id,
    required this.eventId,
    required this.overallRating,
    this.organizationRating,
    this.contentRating,
    this.speakersRating,
    this.wouldRecommend,
    this.comment,
    this.createdAt,
  });

  factory EventSurveyModel.fromJson(Map<String, dynamic> json) {
    return EventSurveyModel(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? '',
      overallRating: _asInt(json['overallRating']) ?? 0,
      organizationRating: _asInt(json['organizationRating']),
      contentRating: _asInt(json['contentRating']),
      speakersRating: _asInt(json['speakersRating']),
      wouldRecommend: json['wouldRecommend'] as bool?,
      comment: json['comment'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  /// Solo `overallRating` viaja siempre. El resto se omite si está vacío: el
  /// backend distingue "sin responder" (null) de un cero, y mandar 0 rompería
  /// el CHECK de la tabla, que exige entre 1 y 5.
  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{'overallRating': overallRating};
    if (organizationRating != null) {
      body['organizationRating'] = organizationRating;
    }
    if (contentRating != null) body['contentRating'] = contentRating;
    if (speakersRating != null) body['speakersRating'] = speakersRating;
    if (wouldRecommend != null) body['wouldRecommend'] = wouldRecommend;
    final trimmed = comment?.trim();
    if (trimmed != null && trimmed.isNotEmpty) body['comment'] = trimmed;
    return body;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

/// Motivo por el que el backend rechazó una encuesta. Se traduce del código
/// HTTP para que la pantalla pueda dar un mensaje concreto en vez de un
/// "error al enviar" que no dice qué hacer.
enum EventSurveyError {
  /// 403: no está registrado en el evento.
  notRegistered,

  /// 409: ya envió su encuesta de este evento.
  alreadySubmitted,

  /// 400: alguna calificación fuera del rango 1..5.
  invalidRating,

  /// 404: el evento no existe.
  eventNotFound,

  /// 401: sesión caducada o ausente.
  unauthorized,

  /// Cualquier otra cosa: red caída, 500, respuesta ilegible.
  unknown,
}

class EventSurveyException implements Exception {
  final EventSurveyError reason;
  final String message;

  const EventSurveyException(this.reason, this.message);

  factory EventSurveyException.fromStatusCode(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return const EventSurveyException(
          EventSurveyError.invalidRating,
          'Revisa las calificaciones: deben estar entre 1 y 5.',
        );
      case 401:
        return const EventSurveyException(
          EventSurveyError.unauthorized,
          'Tu sesión expiró. Vuelve a iniciar sesión para opinar.',
        );
      case 403:
        return const EventSurveyException(
          EventSurveyError.notRegistered,
          'Solo pueden opinar quienes se registraron en el evento.',
        );
      case 404:
        return const EventSurveyException(
          EventSurveyError.eventNotFound,
          'Este evento ya no está disponible.',
        );
      case 409:
        return const EventSurveyException(
          EventSurveyError.alreadySubmitted,
          'Ya enviaste tu opinión de este evento. ¡Gracias!',
        );
      default:
        return EventSurveyException(
          EventSurveyError.unknown,
          'No pudimos enviar tu opinión ($statusCode). Inténtalo más tarde.',
        );
    }
  }

  @override
  String toString() => message;
}
