import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/event_model.dart';
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

  group('eventsForTab', () {
    test('próximos deja fuera los terminados', () {
      final r = eventsForTab(todos, EventTab.proximos);
      expect(r.map((e) => e.id), ['1']);
    });

    test('pasados devuelve el histórico, más reciente primero', () {
      final r = eventsForTab(todos, EventTab.pasados);
      expect(r.map((e) => e.id), ['2', '3']);
    });

    test('mis registros filtra por estado de la inscripción', () {
      final r = eventsForTab(todos, EventTab.misRegistros);
      expect(r.map((e) => e.id), ['2']);
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
  });
}
