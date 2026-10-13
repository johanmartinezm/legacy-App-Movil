import '../models/content_model.dart';

/// El contenido más reciente de Legacy Knowledge, para el banner «Estreno
/// semanal». Hasta el 2026-10-13 ese banner era un texto fijo que no cambiaba
/// con lo publicado.
///
/// Compara la fecha `AAAA-MM-DD` que traen las tres fuentes (contenido propio,
/// canales de YouTube y WordPress). Lo que no tiene fecha —los libros— no
/// compite. Con dos del mismo día gana el primero de la lista, que es el
/// contenido propio: es lo que el equipo carga a mano para destacar.
ContentItem? ultimoEstreno(List<ContentItem> items) {
  ContentItem? ultimo;
  DateTime? fechaUltimo;
  for (final item in items) {
    final fecha = _fecha(item.date);
    if (fecha == null) continue;
    if (fechaUltimo == null || fecha.isAfter(fechaUltimo)) {
      ultimo = item;
      fechaUltimo = fecha;
    }
  }
  return ultimo;
}

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// «13 oct» a partir de `2026-10-13`; cadena vacía si no se entiende. Sin
/// `intl` a propósito: su formato en español exige inicializar los datos de
/// la configuración regional, y esta pantalla no lo hace.
String fechaCortaEstreno(String? date) {
  final fecha = _fecha(date);
  if (fecha == null) return '';
  return '${fecha.day} ${_meses[fecha.month - 1]}';
}

/// Cómo se nombra cada tipo en el banner.
String tipoEstreno(ContentItem item) {
  switch (item.type.toLowerCase()) {
    case 'video':
      return 'Video';
    case 'podcast':
      return 'Podcast';
    case 'book':
    case 'libros':
      return 'Libro';
    default:
      return 'Artículo';
  }
}

DateTime? _fecha(String? date) {
  if (date == null || date.trim().isEmpty) return null;
  return DateTime.tryParse(date.trim());
}
