import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../data/config/image_helper.dart';

/// Tarjeta del Inicio con una foto de fondo y una capa oscura encima, para que
/// el texto blanco se siga leyendo sea cual sea la foto que suba el panel.
///
/// Mientras la imagen carga, o si falla, se ve el azul de la app: la tarjeta
/// nunca queda con un hueco ni con el icono de imagen rota.
class FondoConImagen extends StatelessWidget {
  final String imagenUrl;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// Hacia dónde se oscurece: abajo en las tarjetas altas, donde va el texto;
  /// a la izquierda en las filas, donde va el título.
  final Alignment oscuroHacia;

  /// Opacidad de la capa en el lado claro. En las filas horizontales el
  /// subtítulo cruza hasta el centro y la flecha queda a la derecha, así que
  /// ahí la capa no puede aclararse tanto como en las tarjetas altas.
  final double opacidadLadoClaro;

  const FondoConImagen({
    super.key,
    required this.imagenUrl,
    required this.child,
    required this.borderRadius,
    this.padding = const EdgeInsets.all(14),
    this.oscuroHacia = Alignment.bottomCenter,
    this.opacidadLadoClaro = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: ImageHelper.getProxiedImageUrl(imagenUrl),
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: Color(0xFF1B3156)),
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF1B3156)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-oscuroHacia.x, -oscuroHacia.y),
                  end: oscuroHacia,
                  colors: [
                    const Color(0xFF162540).withValues(alpha: opacidadLadoClaro),
                    const Color(0xFF162540).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
