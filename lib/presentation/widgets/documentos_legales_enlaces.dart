import 'package:flutter/material.dart';

import '../../data/config/documentos_legales.dart';

/// Los dos documentos legales, uno al lado del otro.
///
/// Se repite en el registro y en los avisos legales, y ambas tiendas piden
/// poder llegar a ellos desde la app.
class DocumentosLegalesEnlaces extends StatelessWidget {
  /// Color del texto. Por defecto el azul de acento del tema, que es el único
  /// que se lee sobre el fondo oscuro; ver la nota de `build`.
  final Color? color;
  final double fontSize;

  const DocumentosLegalesEnlaces({super.key, this.color, this.fontSize = 12});

  Future<void> _abrir(BuildContext context, String url) async {
    final abierto = await abrirDocumentoLegal(url);
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el documento. Revisa tu conexión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // `primaryColor` no sirve aquí: con `brightness: dark` Flutter lo resuelve a
    // `colorScheme.surface` (#0B1A2E), no a `primary`, y sobre el fondo del
    // scaffold (#050B15) eso da un contraste de 1.13:1 — los enlaces quedaban
    // ahi pero ilegibles. `colorScheme.primary` (#5A93C4) da ~6:1.
    final estilo = TextStyle(
      fontSize: fontSize,
      color: color ?? Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        InkWell(
          key: const Key('enlace-terminos'),
          onTap: () => _abrir(context, DocumentosLegales.terminos),
          child: Text('Términos y condiciones', style: estilo),
        ),
        InkWell(
          key: const Key('enlace-privacidad'),
          onTap: () => _abrir(context, DocumentosLegales.privacidad),
          child: Text('Política de privacidad', style: estilo),
        ),
      ],
    );
  }
}
