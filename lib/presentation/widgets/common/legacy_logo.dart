import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Versiones oficiales del logo de LEGACY Network.
///
/// Los archivos salen del vector maestro `Log_LegNet-abierto.ai` y viven en
/// `assets/images/brand/`. El Manual de Imagen (julio 2023) prohíbe alterar
/// colores, proporción y tipografía del logo, así que este widget solo expone
/// las versiones que el manual autoriza y nunca deforma el vector.
enum LegacyLogoVariante {
  /// Símbolo más logotipo en una línea. Es la versión principal.
  horizontal,

  /// Símbolo arriba y logotipo debajo, para espacios verticales.
  vertical,

  /// Solo el símbolo (los 15 átomos), para iconos y espacios mínimos.
  simbolo,
}

/// Tinta del logo. El manual admite color completo sobre fondos claros, y una
/// sola tinta —blanca o negra— cuando el fondo no da contraste suficiente.
enum LegacyLogoTinta { color, blanco, negro }

class LegacyLogo extends StatelessWidget {
  const LegacyLogo({
    super.key,
    this.variante = LegacyLogoVariante.horizontal,
    this.tinta = LegacyLogoTinta.blanco,
    this.height,
    this.width,
    this.color,
    this.semanticsLabel = 'LEGACY Network',
  });

  /// Atajo para el símbolo suelto, que es el uso más frecuente en iconos.
  const LegacyLogo.simbolo({
    Key? key,
    LegacyLogoTinta tinta = LegacyLogoTinta.blanco,
    double? height,
    double? width,
    Color? color,
    String? semanticsLabel,
  }) : this(
          key: key,
          variante: LegacyLogoVariante.simbolo,
          tinta: tinta,
          height: height,
          width: width,
          color: color,
          semanticsLabel: semanticsLabel ?? 'LEGACY Network',
        );

  final LegacyLogoVariante variante;
  final LegacyLogoTinta tinta;
  final double? height;
  final double? width;

  /// Tiñe el logo de un solo color. Úsalo solo con una tinta plana (por
  /// ejemplo un icono que cambia de color al activarse); teñir la versión a
  /// color destruiría los cinco azules de la marca.
  final Color? color;

  final String semanticsLabel;

  /// Tamaño mínimo de uso en digital que fija el manual: 100 px de ancho.
  static const double anchoMinimoDigital = 100;

  String get _asset {
    final nombre = switch (variante) {
      LegacyLogoVariante.horizontal => 'horizontal',
      LegacyLogoVariante.vertical => 'vertical',
      LegacyLogoVariante.simbolo => 'simbolo',
    };
    final tono = switch (tinta) {
      LegacyLogoTinta.color => 'color',
      LegacyLogoTinta.blanco => 'blanco',
      LegacyLogoTinta.negro => 'negro',
    };
    return 'assets/images/brand/legacy-$nombre-$tono.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _asset,
      height: height,
      width: width,
      fit: BoxFit.contain,
      semanticsLabel: semanticsLabel,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
