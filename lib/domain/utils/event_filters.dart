/// Filtros del listado de eventos.
///
/// Se resuelven en el cliente sobre la lista ya cargada: `GET /api/events`
/// devuelve todos los eventos, no acepta parámetros de búsqueda y no tiene
/// paginación, así que la lista completa ya está en memoria. Si algún día el
/// backend admite `q`, `category`, `from` y `to`, este archivo es el que se
/// reemplaza por la llamada correspondiente.
library;

import '../models/event_model.dart';
import '../models/registration_model.dart';
import 'busqueda_global.dart' show normalizar;

/// Pestañas del listado.
class EventTab {
  static const String proximos = 'próximos';
  static const String pasados = 'pasados';
  static const String misRegistros = 'mis_registros';
}

/// Valor del filtro de categoría cuando no se filtra por ninguna.
const String kTodasLasCategorias = 'todas';

/// Los eventos que cuentan para «Mis registros». Una inscripción **rechazada**
/// no: el pago no se confirmó y el cupo se liberó (hasta el 2026-11-09 seguía
/// saliendo). La pendiente sí, porque tiene el cupo reservado y desde el detalle
/// se vuelve a abrir el link de pago.
Set<String> eventosInscritos(List<RegistrationModel> inscripciones) => {
  for (final r in inscripciones)
    if (!r.estaRechazada) r.eventId,
};

/// «Mi credencial»: primero lo que sirve para entrar, del evento más cercano al
/// más lejano; después lo que ya pasó, del más reciente al más antiguo. El
/// backend las devuelve por fecha de inscripción, la más reciente primero: el
/// Summit de la semana que viene quedaba debajo de un evento de diciembre en el
/// que la persona se inscribió después (visto el 2026-11-09).
({List<RegistrationModel> vigentes, List<RegistrationModel> pasadas})
credencialesEnOrden(List<RegistrationModel> inscripciones) {
  int porInicio(RegistrationModel a, RegistrationModel b) {
    final DateTime? fa = a.eventStartDate;
    final DateTime? fb = b.eventStartDate;
    if (fa == null && fb == null) return 0;
    if (fa == null) return 1;
    if (fb == null) return -1;
    return fa.compareTo(fb);
  }

  return (
    vigentes: inscripciones.where((r) => !r.eventoTerminado).toList()
      ..sort(porInicio),
    pasadas: inscripciones.where((r) => r.eventoTerminado).toList()
      ..sort((a, b) => porInicio(b, a)),
  );
}

/// Eventos que corresponden a una pestaña, ya ordenados.
///
/// [inscritos] son los ids de los eventos en los que el usuario tiene
/// inscripción, de `GET /api/me/registrations`. «Mis registros» filtraba por
/// `actionStatus == 'registered'`, pero `action_status` es una columna del
/// EVENTO, igual para todos, y el backend solo la devuelve como `register` o
/// `buy`: la pestaña salía vacía para todo el mundo (visto el 2026-10-14). Es el
/// mismo error que ya se había corregido en `event_action_button.dart`.
List<EventModel> eventsForTab(
  List<EventModel> events,
  String tab, {
  Set<String> inscritos = const {},
}) {
  switch (tab) {
    case EventTab.proximos:
      // Del más cercano al más lejano. El backend los devuelve agrupados por
      // el orden de la categoría y después por fecha, así que hasta el
      // 2026-11-09 una masterclass del día 12 salía detrás de todos los Summit
      // del mes. Los que llegan sin fecha, al final.
      return events.where((e) => !e.isPast).toList()
        ..sort((a, b) {
          final DateTime? fa = a.startDate;
          final DateTime? fb = b.startDate;
          if (fa == null && fb == null) return 0;
          if (fa == null) return 1;
          if (fb == null) return -1;
          return fa.compareTo(fb);
        });
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
      return events.where((e) => inscritos.contains(e.id)).toList();
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
