import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Vuelve atrás sin depender de cómo se llegó a la pantalla.
///
/// `context.pop()` a secas **no hace nada** cuando la pantalla es la primera de
/// la pila, que es lo que pasa al abrirla por un enlace profundo
/// (`legacyapp://app/...`) o desde una notificación push: la flecha se queda
/// muerta y no hay forma de salir salvo el botón físico, que ahí cierra la app.
/// Atrapado el 2026-09-02 en Legacy Board.
///
/// [destino] es a dónde ir cuando no hay pila. Para las pantallas del registro
/// conviene `/login`: si además hay sesión, el router lo reenvía a `/home`.
void volverAtras(BuildContext context, {String destino = '/home'}) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(destino);
}
