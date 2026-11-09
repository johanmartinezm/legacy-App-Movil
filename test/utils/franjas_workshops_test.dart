import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/models/workshop_model.dart';
import 'package:legacy_app/domain/utils/franjas_workshops.dart';

/// Mismas reglas que `workshops_eleccion_test.go` del backend: si se separan,
/// la app dejaría continuar con una elección que el servidor rechaza.
WorkshopModel ws(String id, String desde, String hasta) => WorkshopModel(
  id: id,
  eventId: 'ev-1',
  eventTitle: '',
  name: 'Workshop $id',
  room: '',
  speaker: '',
  // El backend manda la hora con la zona de Colombia.
  startDateTime: DateTime.parse('$desde-05:00').toLocal(),
  endDateTime: DateTime.parse('$hasta-05:00').toLocal(),
);

EventModel eventoDel(String dia) => EventModel.fromJson({
  'id': 'ev-1',
  'title': 'Evento',
  'date': '${dia}T00:00:00Z',
  'isFree': true,
});

void main() {
  test('agrupa los que se cruzan aunque sea en parte', () {
    final franjas = calcularFranjas([
      ws('b', '2026-12-10T09:30:00', '2026-12-10T11:00:00'),
      ws('a', '2026-12-10T09:00:00', '2026-12-10T10:00:00'),
      ws('c', '2026-12-10T11:00:00', '2026-12-10T12:00:00'),
      ws('d', '2026-12-11T09:00:00', '2026-12-11T10:00:00'),
    ]);
    expect(franjas.length, 3);
    expect(franjas[0].workshops.map((w) => w.id), ['a', 'b']);
    expect(franjas[0].horario, '09:00 - 11:00');
    expect(franjas[1].workshops.single.id, 'c');
    expect(franjas[2].dia, '2026-12-11');
  });

  test('el día es el de Colombia, no el de UTC', () {
    // 19:00 en Colombia ya es el día siguiente en UTC.
    final franjas = calcularFranjas([
      ws('a', '2026-12-10T18:30:00', '2026-12-10T20:00:00'),
      ws('b', '2026-12-10T19:00:00', '2026-12-10T20:30:00'),
    ]);
    expect(franjas.length, 1);
    expect(franjas.single.dia, '2026-12-10');
  });

  test('la elección cierra a las 00:00 del primer día, hora de Colombia', () {
    final ev = eventoDel('2026-12-10');
    expect(
      eleccionAbierta(ev, ahora: DateTime.parse('2026-12-09T23:59:00-05:00')),
      isTrue,
    );
    expect(
      eleccionAbierta(ev, ahora: DateTime.parse('2026-12-10T00:00:00-05:00')),
      isFalse,
    );
    expect(
      eleccionAbierta(ev, ahora: DateTime.parse('2026-12-12T09:00:00-05:00')),
      isFalse,
    );
  });

  test('la etiqueta del detalle sigue el corte del evento', () {
    final gratis = eventoDel('2026-12-10');
    final dePago = EventModel.fromJson({
      'id': 'ev-2',
      'title': 'De pago',
      'date': '2026-12-10T00:00:00Z',
      'end_date': '2026-12-11T00:00:00Z',
      'isFree': false,
      'price': 120,
    });
    DateTime a(String t) => DateTime.parse(t);

    expect(
      etiquetaDelEvento(gratis, ahora: a('2026-12-09T23:59:00-05:00')),
      'REGISTRO ABIERTO',
    );
    expect(
      etiquetaDelEvento(dePago, ahora: a('2026-12-09T23:59:00-05:00')),
      'PREVENTA ABIERTA',
    );
    // Desde las 00:00 del primer día la app ya no inscribe.
    expect(
      etiquetaDelEvento(dePago, ahora: a('2026-12-10T00:00:00-05:00')),
      'EN CURSO',
    );
    // El último día sigue en curso hasta medianoche.
    expect(
      etiquetaDelEvento(dePago, ahora: a('2026-12-11T23:59:00-05:00')),
      'EN CURSO',
    );
    expect(
      etiquetaDelEvento(dePago, ahora: a('2026-12-12T00:00:00-05:00')),
      'FINALIZADO',
    );
    // Sin fecha de fin, el último día es el primero.
    expect(
      etiquetaDelEvento(gratis, ahora: a('2026-12-11T08:00:00-05:00')),
      'FINALIZADO',
    );
  });

  test('dice qué franja falta', () {
    final franjas = calcularFranjas([
      ws('a', '2026-12-10T09:00:00', '2026-12-10T10:00:00'),
      ws('c', '2026-12-10T11:00:00', '2026-12-10T12:00:00'),
    ]);
    expect(
      motivoEleccionIncompleta(franjas, {0: 'a'}),
      'Falta elegir un workshop el 10/12 de 11:00 a 12:00',
    );
    expect(motivoEleccionIncompleta(franjas, {0: 'a', 1: 'c'}), isNull);
  });
}
