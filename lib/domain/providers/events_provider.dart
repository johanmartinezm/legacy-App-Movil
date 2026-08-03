import 'package:flutter/material.dart';
import '../../data/services/event_service.dart';
import '../models/event_model.dart';
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
        final event = _events[index];
        _events[index] = EventModel(
          id: event.id,
          title: event.title,
          category: event.category,
          date: event.date,
          priceLabel: event.priceLabel,
          price: event.price,
          isFree: event.isFree,
          buttonText: 'Registrado',
          actionStatus: 'registered',
          imageUrl: event.imageUrl,
          description: event.description,
          workshops: event.workshops,
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
}
