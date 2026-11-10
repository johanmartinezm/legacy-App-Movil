/// Los desplegables de editar perfil (generación, sector y sexo).
///
/// Hasta el 2026-11-10 guardar el perfil **pisaba** estos tres campos aunque
/// nadie los tocara: el desplegable necesita un valor de su lista, así que uno
/// vacío o desconocido arrancaba en «Segunda» / «Otro» / «Sin especificar», y
/// eso se mandaba al guardar. Quien solo cambiaba su teléfono quedaba con
/// generación «Segunda», sector «Otro» y, si su sexo venía de la carga masiva
/// con un valor fuera de la lista, sin sexo.
///
/// La regla ahora: **solo viaja el desplegable que la persona cambió**. El
/// backend (`performUpdate`) vuelca el JSON sobre el usuario ya cargado, así que
/// un campo que no llega se queda como estaba.
library;

/// La opción neutra de los tres desplegables. Al guardar viaja como cadena
/// vacía, nunca con este texto.
const String sinEspecificar = 'Sin especificar';

/// Qué mostrar en el desplegable para el valor guardado.
///
/// Un valor que no esté en la lista no se puede mostrar —revienta el
/// `DropdownButtonFormField`—, así que sale como [sinEspecificar]. Eso ya no
/// es peligroso: mientras no se toque, no se manda.
String valorParaDesplegable(String? guardado, List<String> opciones) {
  final valor = (guardado ?? '').trim();
  if (valor.isNotEmpty && opciones.contains(valor)) return valor;
  return sinEspecificar;
}

/// Lo que hay que mandar al guardar, o `null` si el campo no debe viajar.
///
/// - Sin tocar: `null`, aunque lo mostrado no coincida con lo guardado.
/// - Tocado y vuelto a dejar como estaba: `null`.
/// - Tocado y puesto en [sinEspecificar]: cadena vacía (la persona lo borró).
String? valorParaGuardar({
  required String? guardado,
  required String elegido,
  required bool tocado,
}) {
  if (!tocado) return null;
  final nuevo = elegido == sinEspecificar ? '' : elegido;
  if (nuevo == (guardado ?? '').trim()) return null;
  return nuevo;
}
