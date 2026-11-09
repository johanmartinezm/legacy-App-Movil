import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/models/registration_model.dart';
import 'package:legacy_app/domain/utils/event_filters.dart';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T00:00:00Z';

EventModel _evento({
  required String id,
  required String title,
  required String category,
  required DateTime fecha,
  String? location,
  String? speaker,
  String actionStatus = '',
}) {
  return EventModel.fromJson({
    'id': id,
    'title': title,
    'category': category,
    'date': _iso(fecha),
    'location': location,
    'speaker': speaker,
    'actionStatus': actionStatus,
    'price': 0,
    'isFree': true,
  });
}

void main() {
  final DateTime hoy = DateTime.now();

  // Reproduce los datos reales de producción: un evento por venir y dos ya
  // terminados, de categorías distintas.
  final summit = _evento(
    id: '1',
    title: 'LEGACY SUMMIT 2026: Liderazgo y Trascendencia',
    category: 'summit',
    fecha: hoy.add(const Duration(days: 70)),
    location: 'Bogotá',
    speaker: 'Varios',
  );
  final coffee = _evento(
    id: '2',
    title: 'Coffee & Networking: CDMX 2026',
    category: 'coffee',
    fecha: hoy.subtract(const Duration(days: 115)),
    location: 'Ciudad de México',
    actionStatus: 'registered',
  );
  final masterclass = _evento(
    id: '3',
    title: 'Planificación Patrimonial en la Era Digital',
    category: 'masterclass',
    fecha: hoy.subtract(const Duration(days: 138)),
    speaker: 'Ana Gómez',
  );
  final todos = [summit, coffee, masterclass];

  test('Mis registros deja fuera las rechazadas y conserva las pendientes', () {
    RegistrationModel reg(String evento, String estado) =>
        RegistrationModel.fromJson({
          'id': 'reg-$evento',
          'eventId': evento,
          'eventTitle': evento,
          'paymentStatus': 'pending',
          'registrationStatus': estado,
          'qrData': '',
        });

    expect(
      eventosInscritos([
        reg('confirmado', 'confirmed'),
        reg('pendiente', 'pending_payment'),
        reg('rechazado', 'rejected'),
      ]),
      {'confirmado', 'pendiente'},
    );
  });

  test('Mi credencial: vigentes del más cercano, pasadas del más reciente', () {
    String dia(int dentroDe) {
      final d = DateTime.now().toUtc().add(Duration(days: dentroDe));
      return '${d.toIso8601String().substring(0, 10)}T00:00:00Z';
    }

    RegistrationModel reg(String id, int dentroDe) => RegistrationModel.fromJson({
          'id': id,
          'eventId': id,
          'eventTitle': id,
          'eventStartDate': dia(dentroDe),
          'paymentStatus': 'free',
          'registrationStatus': 'confirmed',
          'qrData': 'QR-$id',
        });

    // Por fecha de inscripción, como las devuelve el backend.
    final r = credencialesEnOrden([
      reg('diciembre', 36),
      reg('octubre', -20),
      reg('summit', 9),
      reg('septiembre', -60),
    ]);
    expect(r.vigentes.map((x) => x.id), ['summit', 'diciembre']);
    expect(r.pasadas.map((x) => x.id), ['octubre', 'septiembre']);
  });

  group('eventsForTab', () {
    test('próximos deja fuera los terminados', () {
      final r = eventsForTab(todos, EventTab.proximos);
      expect(r.map((e) => e.id), ['1']);
    });

    test('próximos va del más cercano al más lejano, sin agrupar por categoría', () {
      final hoy = DateTime.now();
      // Como llegan del backend: primero todos los Summit, luego la masterclass.
      final r = eventsForTab([
        _evento(id: 'summit-lejos', title: 'S2', category: 'Summit', fecha: hoy.add(const Duration(days: 30))),
        _evento(id: 'summit-cerca', title: 'S1', category: 'Summit', fecha: hoy.add(const Duration(days: 9))),
        _evento(id: 'masterclass', title: 'M', category: 'Masterclass', fecha: hoy.add(const Duration(days: 3))),
      ], EventTab.proximos);
      expect(r.map((e) => e.id), ['masterclass', 'summit-cerca', 'summit-lejos']);
    });

    test('pasados devuelve el histórico, más reciente primero', () {
      final r = eventsForTab(todos, EventTab.pasados);
      expect(r.map((e) => e.id), ['2', '3']);
    });

    test('mis registros muestra los eventos con inscripción del usuario', () {
      final r = eventsForTab(todos, EventTab.misRegistros, inscritos: {'1', '3'});
      expect(r.map((e) => e.id), ['1', '3']);
    });

    // El fallo del 2026-10-14: action_status es del evento, no del usuario.
    test('mis registros no se fía de actionStatus', () {
      expect(eventsForTab(todos, EventTab.misRegistros), isEmpty);
    });

    test('no altera la lista original', () {
      eventsForTab(todos, EventTab.pasados);
      expect(todos.map((e) => e.id), ['1', '2', '3']);
    });
  });

  group('categoriesOf', () {
    test('devuelve las categorías presentes sin repetir', () {
      expect(categoriesOf(todos), ['summit', 'coffee', 'masterclass']);
    });

    test('ignora vacías y no distingue mayúsculas al deduplicar', () {
      final lista = [
        _evento(id: 'a', title: 'A', category: 'Summit', fecha: hoy),
        _evento(id: 'b', title: 'B', category: 'summit', fecha: hoy),
        _evento(id: 'c', title: 'C', category: '', fecha: hoy),
      ];
      expect(categoriesOf(lista), ['Summit']);
    });
  });

  group('applyEventFilters', () {
    test('sin filtros devuelve todo', () {
      expect(applyEventFilters(todos).length, 3);
    });

    test('busca por título sin distinguir mayúsculas', () {
      final r = applyEventFilters(todos, query: 'networking');
      expect(r.map((e) => e.id), ['2']);
    });

    test('busca por lugar', () {
      final r = applyEventFilters(todos, query: 'méxico');
      expect(r.map((e) => e.id), ['2']);
    });

    test('busca por conferencista', () {
      final r = applyEventFilters(todos, query: 'ana');
      expect(r.map((e) => e.id), ['3']);
    });

    test('filtra por categoría', () {
      final r = applyEventFilters(todos, category: 'masterclass');
      expect(r.map((e) => e.id), ['3']);
    });

    test('combina categoría y texto', () {
      expect(applyEventFilters(todos, category: 'coffee', query: 'cdmx').length, 1);
      expect(applyEventFilters(todos, category: 'coffee', query: 'summit'), isEmpty);
    });

    test('los espacios sueltos no vacían el listado', () {
      expect(applyEventFilters(todos, query: '   ').length, 3);
    });

    test('una búsqueda sin coincidencias devuelve vacío', () {
      expect(applyEventFilters(todos, query: 'zzzz'), isEmpty);
    });

    // Antes de este fix, "planificacion" (como se escribe en un teclado
    // móvil) no encontraba "Planificación", igual que le pasaba al buscador
    // global antes de tener normalizar(). Ver domain/utils/busqueda_global.dart.
    test('encuentra por título sin tildes aunque el original las tenga', () {
      expect(applyEventFilters(todos, query: 'planificacion').single.id, '3');
    });

    test('encuentra por lugar sin tildes aunque el original las tenga', () {
      expect(applyEventFilters(todos, query: 'mexico').single.id, '2');
    });
  });
}
