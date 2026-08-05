import 'package:flutter/material.dart';
import '../../data/services/event_service.dart';
import '../models/event_model.dart';
import '../models/event_survey_model.dart';
import '../models/workshop_model.dart';

class EventsProvider extends ChangeNotifier {
  final EventService _eventService;

  List<EventModel> _events = [];
  final List<WorkshopModel> _agenda = [];
  final Map<String, String> _registrationQrs; // Cache for eventId -> qrData
  bool _isLoading = false;
  String? _errorMessage;

  EventsProvider({EventService? eventService})
    : _eventService = eventService ?? EventService(),
      _registrationQrs = {};

  List<EventModel> get events => _events;
  List<WorkshopModel> get agenda => _agenda;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> getRegistrationQr(String eventId, String token) async {
    if (_registrationQrs.containsKey(eventId)) {
      return _registrationQrs[eventId];
    }

    try {
      final reg = await _eventService.getRegistration(eventId, token);

      // 1. Validar estado de pago primero
      if (reg['payment_status'] == 'pending') {
        throw 'PAYMENT_REQUIRED'; // Esto activará el catch en tu Dialog
      }

      // 2. Usar la llave correcta (qr_data con guion bajo)
      final qrData = reg['qr_data'] as String?;

      if (qrData != null) {
        _registrationQrs[eventId] = qrData;
      }
      return qrData;
    } catch (e) {
      debugPrint('Error fetching registration QR: $e');
      rethrow; // IMPORTANTE: Sin esto, el Dialog nunca entra al bloque catch
    }
  }

  Future<EventModel?> getEventDetails(String id) async {
    try {
      return await _eventService.getEventDetails(id);
    } catch (e) {
      debugPrint('Error loading event details: $e');
      return null;
    }
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventService.getEvents();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerUserToEvent(String eventId, String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _eventService.registerToEvent(eventId, token);

      // Update local state if needed (e.g., change action status)
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        // copyWith y no un EventModel nuevo: reconstruirlo a mano descartaba
        // la fecha, el lugar, el conferencista y el resto de campos opcionales.
        _events[index] = _events[index].copyWith(
          buttonText: 'Registrado',
          actionStatus: 'registered',
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  bool isInAgenda(String workshopId) {
    return _agenda.any((w) => w.id == workshopId);
  }

  Future<void> loadAgenda(String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _eventService.getAgenda(token);
      _agenda.clear();
      for (var json in data) {
        _agenda.add(WorkshopModel.fromJson(json));
      }
    } catch (e) {
      debugPrint('Error loading agenda: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToAgenda(WorkshopModel workshop, String token) async {
    try {
      final success = await _eventService.addToAgenda(workshop.id, token);
      if (success) {
        if (!_agenda.any((w) => w.id == workshop.id)) {
          _agenda.add(workshop);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding to agenda: $e');
      return false;
    }
  }

  Future<bool> removeFromAgenda(String workshopId, String token) async {
    try {
      final success = await _eventService.removeFromAgenda(workshopId, token);
      if (success) {
        _agenda.removeWhere((w) => w.id == workshopId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing from agenda: $e');
      return false;
    }
  }

  Future<bool> submitWorkshopRating({
    required String workshopId,
    required double rating,
    required String comment,
    required String token,
  }) async {
    try {
      return await _eventService.submitWorkshopRating(
        workshopId: workshopId,
        rating: rating,
        comment: comment,
        token: token,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error submitting rating: $e');
      return false;
    }
  }

  /// Encuesta general ya enviada por el usuario, cacheada por evento. `null`
  /// significa "no consultado o sin responder"; para distinguirlo se usa
  /// [hasCheckedSurvey].
  final Map<String, EventSurveyModel> _mySurveys = {};
  final Set<String> _checkedSurveys = {};

  EventSurveyModel? mySurveyFor(String eventId) => _mySurveys[eventId];

  /// Si ya se preguntó al backend por este evento. Sin esto, un usuario que aún
  /// no ha respondido es indistinguible de uno cuyo estado no se ha consultado,
  /// y la pantalla parpadearía entre el formulario y la vista de "ya opinaste".
  bool hasCheckedSurvey(String eventId) => _checkedSurveys.contains(eventId);

  /// Consulta si el usuario ya respondió. Un fallo aquí no se propaga: no poder
  /// comprobarlo no debe impedir que la pantalla se dibuje.
  Future<EventSurveyModel?> loadMyEventSurvey({
    required String eventId,
    required String token,
  }) async {
    try {
      final survey = await _eventService.getMyEventSurvey(
        eventId: eventId,
        token: token,
      );
      if (survey != null) {
        _mySurveys[eventId] = survey;
      } else {
        _mySurveys.remove(eventId);
      }
      _checkedSurveys.add(eventId);
      notifyListeners();
      return survey;
    } catch (e) {
      debugPrint('Error loading event survey: $e');
      return null;
    }
  }

  /// Envía la encuesta general. Devuelve `true` si quedó guardada.
  ///
  /// Un 409 ("ya opinaste") se trata como éxito a efectos de la pantalla: el
  /// objetivo del usuario está cumplido, y lo que procede es mostrarle su
  /// respuesta, no un error. Se recarga para traerla.
  Future<bool> submitEventSurvey({
    required String eventId,
    required EventSurveyModel survey,
    required String token,
  }) async {
    try {
      final saved = await _eventService.submitEventSurvey(
        eventId: eventId,
        survey: survey,
        token: token,
      );
      _mySurveys[eventId] = saved;
      _checkedSurveys.add(eventId);
      _errorMessage = null;
      notifyListeners();
      return true;
    } on EventSurveyException catch (e) {
      _errorMessage = e.message;
      if (e.reason == EventSurveyError.alreadySubmitted) {
        await loadMyEventSurvey(eventId: eventId, token: token);
        return true;
      }
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error submitting event survey: $e');
      notifyListeners();
      return false;
    }
  }
}
