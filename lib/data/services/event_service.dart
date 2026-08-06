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

  Future<Map<String, dynamic>> registerToEvent(String id, String token) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.registerEventEndpoint(id)}',
    );
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Error al matricularse');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
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
        body: jsonEncode({'rating': rating.toInt(), 'comment': comment}),
      );

      return response.statusCode == 201 || response.statusCode == 200;
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
        return data
            .map((json) => RegistrationModel.fromJson(json))
            .toList();
      }
      throw Exception('Error al cargar tus inscripciones (${response.statusCode})');
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
    throw EventSurveyException.fromStatusCode(response.statusCode, response.body);
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
    throw EventSurveyException.fromStatusCode(response.statusCode, response.body);
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

  Future<bool> addToAgenda(String workshopId, String token) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.addToAgendaEndpoint(workshopId)}',
    );
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<bool> removeFromAgenda(String workshopId, String token) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.removeFromAgendaEndpoint(workshopId)}',
    );
    try {
      final response = await _client.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
