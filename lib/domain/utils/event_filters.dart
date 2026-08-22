/// Filtros del listado de eventos.
///
/// Se resuelven en el cliente sobre la lista ya cargada: `GET /api/events`
/// devuelve todos los eventos, no acepta parámetros de búsqueda y no tiene
/// paginación, así que la lista completa ya está en memoria. Si algún día el
/// backend admite `q`, `category`, `from` y `to`, este archivo es el que se
/// reemplaza por la llamada correspondiente.
library;

import '../models/event_model.dart';
import 'busqueda_global.dart' show normalizar;

/// Pestañas del listado.
class EventTab {
  static const String proximos = 'próximos';
  static const String pasados = 'pasados';
  static const String misRegistros = 'mis_registros';
}

/// Valor del filtro de categoría cuando no se filtra por ninguna.
const String kTodasLasCategorias = 'todas';

/// Eventos que corresponden a una pestaña, ya ordenados.
List<EventModel> eventsForTab(List<EventModel> events, String tab) {
  switch (tab) {
    case EventTab.proximos:
      return events.where((e) => !e.isPast).toList();
    case EventTab.pasados:
      // El backend los devuelve por categoría y start_date ascendente. En el
      // histórico interesa lo más reciente primero.
      return events.where((e) => e.isPast).toList()
        ..sort((a, b) {
          final DateTime? fa = a.endDate ?? a.startDate;
          final DateTime? fb = b.endDate ?? b.startDate;
          if (fa == null || fb == null) return 0;
          return fb.compareTo(fa);
        });
    case EventTab.misRegistros:
      return events
          .where(
            (e) =>
                e.actionStatus == 'registered' || e.actionStatus == 'reminder',
          )
          .toList();
    default:
      return const [];
  }
}

/// Categorías presentes en una lista, sin repetir y en orden de aparición.
List<String> categoriesOf(List<EventModel> events) {
  final seen = <String>{};
  final result = <String>[];
  for (final e in events) {
    final c = e.category.trim();
    if (c.isEmpty) continue;
    if (seen.add(c.toLowerCase())) result.add(c);
  }
  return result;
}

/// Aplica búsqueda por texto y filtro de categoría.
///
/// La búsqueda mira también lugar y conferencista: es lo que la gente recuerda
/// de un evento pasado cuando no acierta con el título.
List<EventModel> applyEventFilters(
  List<EventModel> events, {
  String query = '',
  String category = kTodasLasCategorias,
}) {
  final q = normalizar(query.trim());
  return events.where((e) {
    if (category != kTodasLasCategorias &&
        e.category.toLowerCase() != category.toLowerCase()) {
      return false;
    }
    if (q.isEmpty) return true;
    final campos = [e.title, e.category, e.location ?? '', e.speaker ?? '', e.date];
    return campos.any((c) => normalizar(c).contains(q));
  }).toList();
}
