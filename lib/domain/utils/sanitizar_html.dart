/// Saneado del HTML **justo antes de pintarlo**.
///
/// Vive aparte y sin depender de Flutter, igual que `busqueda_global.dart`, para
/// poder probarlo sin montar ningún widget.
///
/// ## Por qué al mostrar y no al guardar
///
/// El backend guarda lo que se le manda tal cual: una publicación de foro con
/// `<script>` se acepta y se almacena entera —comprobado el 2026-08-18—. Sanear
/// al escribir tendría dos problemas: no arregla lo que ya está guardado, y deja
/// el contenido mutilado en la base, donde a lo mejor hacía falta entero. Al
/// mostrar se aplica siempre, también a lo viejo y a lo que venga de fuera.
///
/// ## Qué riesgo cubre de verdad
///
/// En Flutter esto **no es una defensa contra JavaScript**: no hay motor que lo
/// ejecute, así que un `<script>` ya era inerte. Lo que sí evita es que un
/// `<img src="http://…">` metido por un tercero dispare una petición al pintar
/// —delatando la IP de quien lee—, que un `<iframe>` cargue algo ajeno, y que un
/// enlace `javascript:` quede a un toque de distancia. Y deja el terreno hecho
/// para cualquier superficie futura que sí interprete HTML de verdad.
library;

/// Etiquetas que se eliminan **con su contenido**: lo que llevan dentro no es
/// texto para leer, es código o instrucciones de carga.
final _etiquetasConContenido = RegExp(
  r'<\s*(script|style|iframe|object|embed|applet|noscript|template)\b[^>]*>[\s\S]*?<\s*/\s*\1\s*>',
  caseSensitive: false,
);

/// Las mismas etiquetas sin cerrar. Un `<script>` sin `</script>` no casa con la
/// expresión de arriba y se colaría entero.
final _etiquetasSueltas = RegExp(
  r'<\s*/?\s*(script|style|iframe|object|embed|applet|noscript|template|link|meta|base|form|input|button)\b[^>]*>',
  caseSensitive: false,
);

/// Atributos `on…` — `onclick`, `onerror`, `onload`—, que son el sitio donde
/// vive el código en un HTML que parece inofensivo.
final _atributosDeEvento = RegExp(
  '''\\s+on[a-z]+\\s*=\\s*(?:"[^"]*"|'[^']*'|[^\\s>]+)''',
  caseSensitive: false,
);

/// Esquemas de URL que ejecutan en vez de navegar.
final _esquemasPeligrosos = RegExp(
  '''\\s+(?:href|src|xlink:href|formaction|action)\\s*=\\s*(?:"|')?\\s*(?:javascript|vbscript|data)\\s*:[^"'>]*(?:"|')?''',
  caseSensitive: false,
);

/// Devuelve el HTML sin lo que no debería ejecutarse ni cargarse solo.
///
/// Conserva el formato legible —párrafos, negritas, listas, enlaces normales e
/// imágenes—: la idea es que el contenido se siga viendo bien, no dejarlo en
/// texto pelado. Ante la duda se quita, que es el criterio correcto cuando lo
/// que se evalúa es contenido ajeno.
String sanitizarHtml(String? html) {
  if (html == null || html.isEmpty) return '';

  var limpio = html;

  // El orden importa: primero los bloques enteros, porque quitar antes las
  // etiquetas sueltas dejaría su contenido huérfano y visible como texto —el
  // cuerpo de un <style> apareciendo como párrafo, por ejemplo—.
  limpio = limpio.replaceAll(_etiquetasConContenido, '');
  limpio = limpio.replaceAll(_etiquetasSueltas, '');
  limpio = limpio.replaceAll(_atributosDeEvento, '');
  limpio = limpio.replaceAll(_esquemasPeligrosos, '');

  return limpio;
}
