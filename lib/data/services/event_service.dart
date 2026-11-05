import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/event_model.dart';
import '../../domain/models/event_survey_model.dart';
import '../../domain/models/registration_model.dart';
import '../config/api_constants.dart';

class EventService {
  final http.Client _client;

  EventService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<EventModel>> getEvents() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.eventsEndpoint}',
    );
    try {
      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EventModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar eventos (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<EventModel> getEventDetails(String id) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.eventDetailsEndpoint(id)}',
    );
    try {
      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return EventModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al cargar detalles del evento');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Inscribe a quien tiene la sesión abierta. El contacto del participante es
  /// opcional y **no cambia de quién es la entrada** —eso lo fija el token—:
  /// es a quién llamar si no aparece, y puede diferir del perfil.
  ///
  /// `workshops` son los ids elegidos, uno por franja (§10 del plan de
  /// workshops). El servidor rechaza una elección incompleta con un motivo en
  /// español, que llega como [MotivoDelServidor].
  Future<Map<String, dynamic>> registerToEvent(
    String id,
    String token, {
    String? participantName,
    String? participantEmail,
    String? participantPhone,
    List<String>? workshops,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.registerEventEndpoint(id)}',
    );

    final cuerpo = <String, dynamic>{
      if (participantName != null && participantName.isNotEmpty)
        'participant_name': participantName,
      if (participantEmail != null && participantEmail.isNotEmpty)
        'participant_email': participantEmail,
      if (participantPhone != null && participantPhone.isNotEmpty)
        'participant_phone': participantPhone,
      if (workshops != null && workshops.isNotEmpty) 'workshops': workshops,
    };

    final http.Response response;
    try {
      response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Sin datos no se manda cuerpo: el backend solo lo lee si llega
        // Content-Type JSON, y un objeto vacío no aporta nada.
        body: cuerpo.isEmpty ? null : jsonEncode(cuerpo),
      );
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    // Antes esto se leía como JSON dentro del mismo try, y el backend responde
    // en texto plano: el usuario veía «Error de conexión: FormatException» en
    // vez de, por ejemplo, «Falta elegir un workshop el 10/12 de 11:00 a 12:00».
    throw MotivoDelServidor(
      motivoDeRespuesta(response.body, 'No pudimos reservar tu cupo'),
    );
  }

  /// Cambia los workshops elegidos en la inscripción a un evento. Solo hasta el
  /// día anterior; desde el primer día el servidor responde 409. Devuelve la
  /// agenda nueva, con los workshops elegidos de todos los eventos.
  Future<List<dynamic>> elegirMisWorkshops(
    String eventId,
    List<String> workshops,
    String token,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.misWorkshopsEndpoint(eventId)}',
    );
    final http.Response response;
    try {
      response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'workshops': workshops}),
      );
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw MotivoDelServidor(
      motivoDeRespuesta(response.body, 'No pudimos guardar tus workshops'),
    );
  }

  // getRegistration se retiró: era un alias de registerToEvent, es decir, un
  // POST de escritura usado para leer. Su único consumidor era el QR de la
  // agenda, ahora sustituido por getMyRegistrations.

  Future<bool> submitWorkshopRating({
    required String workshopId,
    required double rating,
    required String comment,
    required String token,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.workshopRatingEndpoint(workshopId)}',
    );
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // round() y no toInt(): un 4,5 no debe convertirse en 4 en silencio.
        body: jsonEncode({'rating': rating.round(), 'comment': comment}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      // 409 «ya calificaste este taller», 422 «podrás calificarlo cuando
      // termine»: el backend explica el motivo en español y se muestra tal
      // cual. Antes cualquier rechazo salía como un «Error» sin más.
      final motivo = response.body.trim();
      if (response.statusCode >= 400 &&
          response.statusCode < 500 &&
          motivo.isNotEmpty) {
        throw MotivoDelServidor(motivo);
      }
      return false;
    } on MotivoDelServidor {
      rethrow;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Todos los eventos en los que el usuario está inscrito, con su QR.
  ///
  /// Sustituye al apaño de pedir el QR llamando a `registerToEvent`, que usaba
  /// un `POST` de escritura para leer y solo servía para un evento a la vez.
  Future<List<RegistrationModel>> getMyRegistrations(String token) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.myRegistrationsEndpoint}',
    );
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') return [];
        final List<dynamic> data = jsonDecode(body);
        return data.map((json) => RegistrationModel.fromJson(json)).toList();
      }
      throw Exception(
        'Error al cargar tus inscripciones (${response.statusCode})',
      );
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Envía la encuesta general del evento.
  ///
  /// A diferencia de [submitWorkshopRating], que devuelve un `bool` y borra el
  /// motivo del fallo, aquí se lanza [EventSurveyException]: "no estás
  /// registrado" y "ya opinaste" piden mensajes distintos en pantalla.
  Future<EventSurveyModel> submitEventSurvey({
    required String eventId,
    required EventSurveyModel survey,
    required String token,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.eventSurveyEndpoint(eventId)}',
    );

    final http.Response response;
    try {
      response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(survey.toJson()),
      );
    } catch (e) {
      throw EventSurveyException(
        EventSurveyError.unknown,
        'Error de conexión: $e',
      );
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      return EventSurveyModel.fromJson(jsonDecode(response.body));
    }
    throw EventSurveyException.fromStatusCode(
      response.statusCode,
      response.body,
    );
  }

  /// Devuelve la encuesta ya enviada, o `null` si el usuario todavía no ha
  /// respondido: el backend contesta 204 en ese caso, que no es un error.
  Future<EventSurveyModel?> getMyEventSurvey({
    required String eventId,
    required String token,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.myEventSurveyEndpoint(eventId)}',
    );

    final http.Response response;
    try {
      response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw EventSurveyException(
        EventSurveyError.unknown,
        'Error de conexión: $e',
      );
    }

    if (response.statusCode == 204) return null;
    if (response.statusCode == 200) {
      if (response.body.trim().isEmpty) return null;
      return EventSurveyModel.fromJson(jsonDecode(response.body));
    }
    throw EventSurveyException.fromStatusCode(
      response.statusCode,
      response.body,
    );
  }

  Future<List<dynamic>> getAgenda(String token) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.getAgendaEndpoint}',
    );
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar agenda');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // addToAgenda y removeFromAgenda se retiraron el 2026-11-05: «Mi agenda» ya
  // no es una lista aparte, son los workshops elegidos al inscribirse.
}

/// El texto que el servidor da como motivo. El backend responde en texto plano
/// (`http.Error`), pero se acepta también un JSON con `message` o `error`.
String motivoDeRespuesta(String cuerpo, String porDefecto) {
  var texto = cuerpo.trim();
  try {
    final json = jsonDecode(texto);
    if (json is Map) {
      texto = (json['message'] ?? json['error'] ?? '').toString().trim();
    }
  } catch (_) {}
  if (texto.isEmpty) return porDefecto;
  return texto[0].toUpperCase() + texto.substring(1);
}

/// Rechazo del servidor con un motivo pensado para mostrarse al usuario.
class MotivoDelServidor implements Exception {
  final String mensaje;
  const MotivoDelServidor(this.mensaje);

  @override
  String toString() => mensaje;
}
