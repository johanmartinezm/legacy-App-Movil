import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/event_model.dart';

/// El backend serializa `start_date`/`end_date` (columnas `date`) como
/// medianoche UTC, así que los casos reproducen ese formato exacto.
String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00Z';

EventModel _evento({String? date, String? endDate}) {
  return EventModel.fromJson({
    'id': 'e1',
    'title': 'Evento de prueba',
    'category': 'Summit',
    if (date != null) 'date': date,
    if (endDate != null) 'end_date': endDate,
    'price': 0,
    'isFree': true,
  });
}

void main() {
  final DateTime hoy = DateTime.now();

  group('EventModel.isPast', () {
    test('un evento de ayer es pasado', () {
      final e = _evento(date: _iso(hoy.subtract(const Duration(days: 1))));
      expect(e.isPast, isTrue);
    });

    test('un evento de hoy sigue siendo próximo toda la jornada', () {
      final e = _evento(date: _iso(hoy));
      expect(e.isPast, isFalse);
    });

    test('un evento futuro no es pasado', () {
      final e = _evento(date: _iso(hoy.add(const Duration(days: 30))));
      expect(e.isPast, isFalse);
    });

    test('manda end_date: empezó ayer pero termina mañana', () {
      final e = _evento(
        date: _iso(hoy.subtract(const Duration(days: 1))),
        endDate: _iso(hoy.add(const Duration(days: 1))),
      );
      expect(e.isPast, isFalse);
    });

    test('un evento de varios días ya terminado es pasado', () {
      final e = _evento(
        date: _iso(hoy.subtract(const Duration(days: 5))),
        endDate: _iso(hoy.subtract(const Duration(days: 3))),
      );
      expect(e.isPast, isTrue);
    });

    test('sin fecha utilizable no se oculta del listado', () {
      expect(_evento().isPast, isFalse);
      expect(_evento(date: 'proximamente').isPast, isFalse);
    });
  });

  group('EventModel.fromJson', () {
    test('conserva la fecha cruda y muestra dd/MM/yyyy', () {
      final e = _evento(date: '2026-03-09T00:00:00Z');
      expect(e.date, '09/03/2026');
      expect(e.startDate, isNotNull);
      expect(e.startDate!.year, 2026);
      expect(e.startDate!.month, 3);
      expect(e.startDate!.day, 9);
    });

    test('una fecha no ISO se muestra tal cual y deja startDate nulo', () {
      final e = _evento(date: 'Por confirmar');
      expect(e.date, 'Por confirmar');
      expect(e.startDate, isNull);
    });
  });

  group('EventModel.copyWith', () {
    test('registrarse a un evento pasado no lo devuelve a próximos', () {
      final e = _evento(date: _iso(hoy.subtract(const Duration(days: 10))));
      final registrado = e.copyWith(
        buttonText: 'Registrado',
        actionStatus: 'registered',
      );
      expect(registrado.actionStatus, 'registered');
      expect(registrado.startDate, e.startDate);
      expect(registrado.isPast, isTrue);
    });
  });
}
