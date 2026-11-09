import 'package:flutter/material.dart';
import '../../data/services/event_service.dart';
import '../models/event_model.dart';
import '../models/event_survey_model.dart';
import '../models/registration_model.dart';
import '../models/workshop_model.dart';

class EventsProvider extends ChangeNotifier {
  final EventService _eventService;

  List<EventModel> _events = [];
  final List<WorkshopModel> _agenda = [];
  bool _agendaCargada = false;
  bool _isLoading = false;
  String? _errorMessage;

  EventsProvider({EventService? eventService})
    : _eventService = eventService ?? EventService();

  List<EventModel> get events => _events;
  List<WorkshopModel> get agenda => _agenda;

  /// Si ya se pidió la agenda alguna vez en esta sesión. La usa el detalle del
  /// evento para saber qué workshops elegí sin pedirla en cada apertura.
  bool get agendaCargada => _agendaCargada;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // getRegistrationQr se retiró junto con QrAttendanceDialog: obtenía el código
  // haciendo un POST /register —un endpoint de escritura usado para leer— y solo
  // servía para un evento a la vez. Lo sustituye loadMyRegistrations, que trae
  // todas las inscripciones con su QR de una sola llamada.

  Future<EventModel?> getEventDetails(String id) async {
    try {
      return await _eventService.getEventDetails(id);
    } catch (e) {
      debugPrint('Error loading event details: $e');
      return null;
    }
  }

  /// Por qué falló la última carga del listado, o null si salió bien. Va aparte
  /// de [errorMessage], que también lo usan la inscripción y la calificación:
  /// sin esto el listado no sabía que había fallado y decía «No hay eventos
  /// disponibles», y al quedarse vacío «Mis registros» decía «Aún no te has
  /// registrado» a quien sí lo estaba (visto el 2026-11-06 al perder la red).
  String? _eventsError;
  String? get eventsError => _eventsError;

  Future<void> loadEvents() async {
    _isLoading = true;
    _eventsError = null;
    notifyListeners();

    try {
      _events = await _eventService.getEvents();
    } catch (e) {
      // Se conserva la lista anterior: si ya había eventos, siguen a la vista.
      _eventsError = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error loading events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerUserToEvent(
    String eventId,
    String token, {
    String? participantName,
    String? participantEmail,
    String? participantPhone,
    List<String>? workshopIds,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _eventService.registerToEvent(
        eventId,
        token,
        participantName: participantName,
        participantEmail: participantEmail,
        participantPhone: participantPhone,
        workshops: workshopIds,
      );

      // Se recargan las inscripciones reales en vez de parchear el evento en
      // memoria con actionStatus: 'registered'. Aquello no sobrevivia a un
      // refresco: action_status es una columna del EVENTO, igual para todos los
      // usuarios, y el backend la devuelve siempre como 'register' o 'buy', asi
      // que al recargar el listado el usuario volvia a ver "Reservar cupo"
      // estando ya inscrito.
      await loadMyRegistrations(token);
      // Los workshops elegidos son «Mi agenda»: se recarga para que el detalle
      // y el cronograma los marquen sin esperar a volver al listado.
      if (workshopIds != null && workshopIds.isNotEmpty) {
        await loadAgenda(token);
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
      _agendaCargada = true;
    } catch (e) {
      debugPrint('Error loading agenda: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Los workshops que elegí en mi inscripción a ese evento. Vacío si no
  /// elegí ninguno: las inscripciones de antes del 2026-11-05, las del panel y
  /// las de la carga masiva no tienen elección.
  List<WorkshopModel> elegidosDe(String eventId) =>
      _agenda.where((w) => w.eventId == eventId).toList();

  /// Cambia mis workshops de un evento, hasta el día anterior. Devuelve null si
  /// salió bien, o el motivo del rechazo para mostrarlo tal cual.
  Future<String?> elegirMisWorkshops(
    String eventId,
    List<String> workshopIds,
    String token,
  ) async {
    try {
      final data = await _eventService.elegirMisWorkshops(
        eventId,
        workshopIds,
        token,
      );
      _agenda
        ..clear()
        ..addAll(data.map((j) => WorkshopModel.fromJson(j)));
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  // addToAgenda y removeFromAgenda se retiraron el 2026-11-05: la agenda son
  // los workshops elegidos al inscribirse, y se cambian todos juntos con
  // elegirMisWorkshops.

  /// Mis calificaciones de workshops, `workshopId → estrellas`. Se piden por
  /// evento la primera vez que se pinta uno de sus workshops. Hasta el
  /// 2026-11-09 la app no las conocía: ofrecía «Calificar experiencia» en un
  /// workshop ya calificado y solo al enviar decía «ya calificaste».
  final Map<String, int> _misCalificaciones = {};
  final Set<String> _calificacionesPedidas = {};
  // Este provider sobrevive al cierre de sesión: si cambia la cuenta, lo de la
  // anterior no vale.
  String? _tokenDeCalificaciones;

  int? calificacionDe(String workshopId) => _misCalificaciones[workshopId];

  Future<void> cargarMisCalificaciones(String eventId, String token) async {
    if (token != _tokenDeCalificaciones) {
      _misCalificaciones.clear();
      _calificacionesPedidas.clear();
      _tokenDeCalificaciones = token;
    }
    if (!_calificacionesPedidas.add(eventId)) return;
    try {
      final deEsteEvento = await _eventService.getMyWorkshopRatings(
        eventId: eventId,
        token: token,
      );
      if (token != _tokenDeCalificaciones) return;
      _misCalificaciones.addAll(deEsteEvento);
      notifyListeners();
    } catch (e) {
      // Sin ellas se ofrece calificar como antes, y el servidor sigue
      // rechazando la segunda. La próxima vez se vuelve a pedir.
      _calificacionesPedidas.remove(eventId);
      debugPrint('Error loading my workshop ratings: $e');
    }
  }

  Future<bool> submitWorkshopRating({
    required String workshopId,
    required double rating,
    required String comment,
    required String token,
  }) async {
    // Sin esto, un fallo sin motivo mostraría el error de otra operación.
    _errorMessage = null;
    try {
      final ok = await _eventService.submitWorkshopRating(
        workshopId: workshopId,
        rating: rating,
        comment: comment,
        token: token,
      );
      if (ok && token == _tokenDeCalificaciones) {
        _misCalificaciones[workshopId] = rating.round();
        notifyListeners();
      }
      return ok;
    } on MotivoDelServidor catch (e) {
      // Rechazo definitivo («ya calificaste este taller»): reintentar no
      // cambia nada, así que se propaga para que el diálogo se cierre.
      _errorMessage = e.mensaje;
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error submitting rating: $e');
      return false;
    }
  }

  /// Inscripciones del usuario, para la pantalla "Mi credencial".
  List<RegistrationModel> _myRegistrations = [];
  bool _loadingRegistrations = false;
  String? _registrationsError;

  List<RegistrationModel> get myRegistrations => _myRegistrations;
  bool get loadingRegistrations => _loadingRegistrations;
  String? get registrationsError => _registrationsError;

  /// Inscripción del usuario a un evento concreto, o `null` si no está
  /// inscrito. Requiere haber llamado antes a [loadMyRegistrations].
  RegistrationModel? registrationFor(String eventId) {
    for (final reg in _myRegistrations) {
      if (reg.eventId == eventId) return reg;
    }
    return null;
  }

  /// Si ya se consultaron las inscripciones. Sin esto no se puede distinguir
  /// "no está inscrito" de "todavía no lo sabemos", y la pantalla ofrecería
  /// reservar un cupo que el usuario ya tiene.
  bool _registrationsLoaded = false;
  bool get registrationsLoaded => _registrationsLoaded;

  Future<void> loadMyRegistrations(String token) async {
    _loadingRegistrations = true;
    _registrationsError = null;
    notifyListeners();

    try {
      _myRegistrations = await _eventService.getMyRegistrations(token);
      _registrationsLoaded = true;
    } catch (e) {
      _registrationsError = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error loading registrations: $e');
    } finally {
      _loadingRegistrations = false;
      notifyListeners();
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
