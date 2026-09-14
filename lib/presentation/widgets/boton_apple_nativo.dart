import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// El botón de Sign in with Apple del propio sistema
/// (`ASAuthorizationAppleIDButton`), incrustado como vista nativa.
///
/// Apple rechazó la 1.0 (21) por la directriz 4: el botón era un contenedor
/// propio con el texto «Apple» y, según el motivo citado, el arte del logotipo
/// no venía de Apple Design Resources. Dibujarlo nosotros —o con el
/// `SignInWithAppleButton` del paquete, que lo pinta con un `CustomPainter`—
/// deja abierta esa misma objeción. El botón del sistema no: no hay ningún
/// recurso gráfico que revisar.
///
/// El registro de la vista está en `ios/Runner/AppDelegate.swift`.
class BotonAppleNativo extends StatefulWidget {
  const BotonAppleNativo({
    super.key,
    required this.onPressed,
    this.height = 52,
    this.radio = 12,
    this.claro = true,
  });

  final VoidCallback onPressed;
  final double height;
  final double radio;

  /// Blanco sobre el fondo oscuro del login. En `false`, el negro de la guía.
  final bool claro;

  /// Solo iOS trae `ASAuthorizationAppleIDButton`. En el resto no hay que pintar
  /// nada: el botón de Apple ya se oculta fuera de iOS y macOS porque en Android
  /// haría falta un Service ID web que no está configurado.
  static bool get disponible =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  State<BotonAppleNativo> createState() => _BotonAppleNativoState();
}

class _BotonAppleNativoState extends State<BotonAppleNativo> {
  MethodChannel? _canal;

  @override
  void dispose() {
    _canal?.setMethodCallHandler(null);
    super.dispose();
  }

  void _alCrearse(int id) {
    _canal = MethodChannel('legacy/boton-apple/$id')
      ..setMethodCallHandler((call) async {
        if (call.method == 'tocado') widget.onPressed();
      });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      // Sin ancho explícito, la vista nativa nace con 0 px dentro de un Row y el
      // botón queda invisible aunque exista.
      width: double.infinity,
      child: UiKitView(
        viewType: 'legacy/boton-apple',
        layoutDirection: TextDirection.ltr,
        creationParams: {'claro': widget.claro, 'radio': widget.radio},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _alCrearse,
      ),
    );
  }
}
