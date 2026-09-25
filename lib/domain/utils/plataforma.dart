import 'package:flutter/foundation.dart';

/// En iOS la app no puede mostrar el precio de Legacy+ ni invitar a activarlo:
/// incluye contenido reservado, y la directriz 3.1.1 de Apple obliga a vender
/// eso con compra dentro de la app. App Review preguntó por el modelo de
/// negocio (2.1(b)) al ver el precio en la build 24.
///
/// Con `defaultTargetPlatform` y no con `Platform.isIOS` para no romper la web,
/// donde `dart:io` no existe.
bool get ocultarVentaLegacyPlus =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
