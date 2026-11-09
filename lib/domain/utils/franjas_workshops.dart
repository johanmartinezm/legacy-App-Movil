import '../models/event_model.dart';
import '../models/workshop_model.dart';

/// Reglas para elegir los workshops de un evento (§10 del plan de workshops,
/// decidido el 2026-11-05). Son las mismas que aplica el backend en
/// `workshops_eleccion.go`: la app las usa para pintar la hoja y avisar antes
/// de enviar, pero quien decide es el servidor.
///
/// - En cada franja de cada día se elige exactamente un workshop.
/// - Una franja son los workshops del mismo día, en hora de Colombia, cuyos
///   horarios se cruzan, aunque sea en parte.
/// - Se elige o se cambia hasta el día anterior al evento. Desde las 00:00 del
///   primer día, nadie, y la app ya no deja inscribirse.

/// Colombia es UTC-5 todo el año. La hora del teléfono no sirve: alguien de
/// viaje vería otro día y otras franjas que el servidor.
DateTime enColombia(DateTime t) => t.toUtc().subtract(const Duration(hours: 5));

String _dia(DateTime t) {
  final c = enColombia(t);
  return '${c.year.toString().padLeft(4, '0')}-'
      '${c.month.toString().padLeft(2, '0')}-'
      '${c.day.toString().padLeft(2, '0')}';
}

class FranjaWorkshops {
  final DateTime inicio;
  DateTime fin;
  final List<WorkshopModel> workshops;

  FranjaWorkshops(this.inicio, this.fin, this.workshops);

  /// Día de la franja en Colombia, como AAAA-MM-DD.
  String get dia => _dia(inicio);

  /// «09:00 - 11:00», en hora de Colombia.
  String get horario => '${_hhmm(inicio)} - ${_hhmm(fin)}';

  static String _hhmm(DateTime t) {
    final c = enColombia(t);
    return '${c.hour.toString().padLeft(2, '0')}:'
        '${c.minute.toString().padLeft(2, '0')}';
  }
}

/// Agrupa los workshops en franjas: ordena por inicio y alarga la franja
/// mientras el siguiente empiece antes de que acabe la actual. Uno que empieza
/// justo cuando acaba el anterior ya va en otra.
List<FranjaWorkshops> calcularFranjas(List<WorkshopModel> workshops) {
  final ordenados = [...workshops]
    ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

  final franjas = <FranjaWorkshops>[];
  for (final w in ordenados) {
    if (franjas.isNotEmpty) {
      final actual = franjas.last;
      if (actual.dia == _dia(w.startDateTime) &&
          w.startDateTime.isBefore(actual.fin)) {
        actual.workshops.add(w);
        if (w.endDateTime.isAfter(actual.fin)) actual.fin = w.endDateTime;
        continue;
      }
    }
    franjas.add(FranjaWorkshops(w.startDateTime, w.endDateTime, [w]));
  }
  return franjas;
}

/// Si todavía se pueden elegir workshops e inscribirse desde la app: hasta el
/// día anterior al primer día del evento. Las fechas del evento llegan como
/// medianoche UTC de una columna `date`, así que se comparan como día.
bool eleccionAbierta(EventModel evento, {DateTime? ahora}) {
  final inicio = evento.startDate;
  if (inicio == null) return true;
  final u = inicio.toUtc();
  final primerDia =
      '${u.year.toString().padLeft(4, '0')}-'
      '${u.month.toString().padLeft(2, '0')}-'
      '${u.day.toString().padLeft(2, '0')}';
  return _dia(ahora ?? DateTime.now()).compareTo(primerDia) < 0;
}

/// Fecha de una columna `date` del evento (medianoche UTC) como día.
String _diaDeFecha(DateTime fecha) {
  final u = fecha.toUtc();
  return '${u.year.toString().padLeft(4, '0')}-'
      '${u.month.toString().padLeft(2, '0')}-'
      '${u.day.toString().padLeft(2, '0')}';
}

/// La etiqueta del detalle del evento. Hasta el 2026-11-09 dependía solo de si
/// era gratuito, así que un evento ya terminado seguía diciendo «REGISTRO
/// ABIERTO». Ahora sigue el mismo corte que [eleccionAbierta]: desde el primer
/// día la app no inscribe, y pasado el último día el evento terminó (lo mismo
/// que dice «FINALIZADO» en el listado).
String etiquetaDelEvento(EventModel evento, {DateTime? ahora}) {
  final hoy = _dia(ahora ?? DateTime.now());
  final ultimo = evento.endDate ?? evento.startDate;
  if (ultimo != null && _diaDeFecha(ultimo).compareTo(hoy) < 0) {
    return 'FINALIZADO';
  }
  if (!eleccionAbierta(evento, ahora: ahora)) return 'EN CURSO';
  return evento.isFree ? 'REGISTRO ABIERTO' : 'PREVENTA ABIERTA';
}

/// Qué falta en una elección, o null si vale. Es el mismo texto que daría el
/// servidor, para que la app pueda decirlo sin hacer la llamada.
String? motivoEleccionIncompleta(
  List<FranjaWorkshops> franjas,
  Map<int, String> elegidoPorFranja,
) {
  for (var i = 0; i < franjas.length; i++) {
    if (!elegidoPorFranja.containsKey(i)) {
      final f = franjas[i];
      final c = enColombia(f.inicio);
      final fecha =
          '${c.day.toString().padLeft(2, '0')}/${c.month.toString().padLeft(2, '0')}';
      return 'Falta elegir un workshop el $fecha de '
          '${FranjaWorkshops._hhmm(f.inicio)} a ${FranjaWorkshops._hhmm(f.fin)}';
    }
  }
  return null;
}
