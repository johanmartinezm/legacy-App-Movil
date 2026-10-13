/// Palabras de un texto libre: lo que hay entre espacios o saltos de línea.
///
/// Se usa para el tope de 500 palabras del detalle de la solicitud de
/// asesoría (2026-10-13). Contar caracteres sería más simple, pero el cliente
/// pidió el límite en palabras, que es como lo entiende quien escribe.
int contarPalabras(String texto) {
  final limpio = texto.trim();
  if (limpio.isEmpty) return 0;
  return limpio.split(RegExp(r'\s+')).length;
}
