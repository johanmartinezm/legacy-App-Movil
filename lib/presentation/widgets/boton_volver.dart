import 'package:flutter/material.dart';

import '../../domain/utils/volver_atras.dart';

/// La flecha de atrás de toda la app.
///
/// Antes cada pantalla dibujaba la suya: círculo en Perfil y Eventos, cuadrado
/// redondeado en Legacy Knowledge y Programas, y el icono pelado en las demás,
/// con seis tamaños distintos (14, 15, 16, 18, 20 y 24) y tres iconos
/// diferentes. Unificado el 2026-09-02 a petición del cliente.
///
/// El círculo con fondo lleva algo detrás a propósito: hay pantallas donde la
/// flecha cae sobre una foto —el detalle de un artículo, la ficha de un libro—
/// y un icono suelto se pierde ahí.
class BotonVolver extends StatelessWidget {
  /// A dónde ir cuando no hay nada que desapilar, es decir cuando se llegó por
  /// enlace profundo o desde una notificación. Ver [volverAtras].
  final String destino;

  /// Para las pantallas que necesitan hacer algo más que volver —descartar un
  /// formulario, cerrar un buscador—. Si se pasa, manda esto.
  final VoidCallback? onTap;

  const BotonVolver({super.key, this.destino = '/home', this.onTap});

  /// Lo que se ve: 32 px. El área que responde al dedo es mayor.
  static const double _diametro = 32;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: InkResponse(
        onTap: onTap ?? () => volverAtras(context, destino: destino),
        radius: 24,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: _diametro,
              height: _diametro,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B1A2E).withValues(alpha: 0.6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
