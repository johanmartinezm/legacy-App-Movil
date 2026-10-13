import 'package:http/http.dart' as http;

/// El backend respondió 403 porque la sección es solo para usuarios Legacy+
/// (foros y beneficios, desde el 2026-10-13). Las pantallas la distinguen de
/// un error de red para explicarlo en vez de mostrar «Error».
class SoloPlusException implements Exception {
  final String mensaje;

  const SoloPlusException([this.mensaje = mensajeSoloPlus]);

  @override
  String toString() => mensaje;
}

/// Lo mismo que dice el backend (handler/http/usuario_plus.go).
const mensajeSoloPlus = 'Esta sección es para usuarios Legacy+.';

/// Lanza [SoloPlusException] si la respuesta es un 403 de sección Legacy+.
void comprobarSoloPlus(http.Response response) {
  if (response.statusCode == 403) {
    final cuerpo = response.body.trim();
    throw SoloPlusException(cuerpo.isEmpty ? mensajeSoloPlus : cuerpo);
  }
}
