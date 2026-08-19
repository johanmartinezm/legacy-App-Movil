import '../models/resultado_busqueda.dart';

/// Filtrado de la busqueda global. Vive aparte de la pantalla y sin depender de
/// Flutter, igual que `event_filters.dart`, para poder probarlo sin pintar nada.
///
/// Todo el filtrado ocurre en el cliente. Es la misma decision que se tomo con
/// los filtros de eventos: el backend no acepta parametros de busqueda en
/// ninguna de estas listas, y las cinco fuentes ya se descargan enteras. Si
/// algun dia el backend busca de verdad, este archivo es el unico que cambia.

/// Quita las tildes y pasa a minusculas.
///
/// Sin esto, buscar "sesion" no encontraria "Sesión de bienvenida", que es
/// justo lo que la gente escribe: en un teclado movil las tildes cuestan.
String normalizar(String texto) {
  const conTilde = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const sinTilde = 'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC';

  final resultado = StringBuffer();
  for (final rune in texto.runes) {
    final caracter = String.fromCharCode(rune);
    final posicion = conTilde.indexOf(caracter);
    resultado.write(posicion == -1 ? caracter : sinTilde[posicion]);
  }
  return resultado.toString().toLowerCase();
}

/// Filtra por todas las palabras de la consulta, en cualquier orden.
///
/// "summit liderazgo" encuentra "LEGACY SUMMIT 2026: Liderazgo y Trascendencia"
/// aunque las palabras no esten juntas ni en ese orden. Buscar la frase entera
/// como una sola cadena fallaria en ese caso, que es de los mas comunes.
List<ResultadoBusqueda> filtrar(List<ResultadoBusqueda> todos, String consulta) {
  final palabras = palabrasDe(consulta);
  if (palabras.isEmpty) return const [];

  return todos.where((r) => palabras.every((p) => r.textoBuscable.contains(p))).toList();
}

/// Parte la consulta en palabras ya normalizadas, sin vacios.
List<String> palabrasDe(String consulta) =>
    normalizar(consulta).split(' ').where((p) => p.isNotEmpty).toList();

/// Indica si un texto cualquiera satisface la consulta, con la misma regla que
/// [filtrar]: todas las palabras, en cualquier orden y sin tildes.
///
/// Existe para que el buscador de Legacy Knowledge no reimplemente el criterio:
/// filtra `ContentItem`, no `ResultadoBusqueda`, pero debe comportarse igual.
/// Una consulta vacia coincide con todo, porque ahi el buscador no filtra nada.
bool coincide(String texto, String consulta) {
  final palabras = palabrasDe(consulta);
  if (palabras.isEmpty) return true;

  final objetivo = normalizar(texto);
  return palabras.every((p) => objetivo.contains(p));
}

/// Agrupa conservando el orden de `TipoResultado`, para que las secciones
/// salgan siempre en el mismo sitio y la lista no baile entre busquedas.
Map<TipoResultado, List<ResultadoBusqueda>> agrupar(List<ResultadoBusqueda> resultados) {
  final agrupados = <TipoResultado, List<ResultadoBusqueda>>{};
  for (final tipo in TipoResultado.values) {
    final delTipo = resultados.where((r) => r.tipo == tipo).toList();
    if (delTipo.isNotEmpty) agrupados[tipo] = delTipo;
  }
  return agrupados;
}
