import 'package:url_launcher/url_launcher.dart';

/// Los documentos legales publicados de Legacy Network.
///
/// Viven aquí y no escritos a mano en cada pantalla porque las dos tiendas
/// exigen que sean alcanzables desde la app, y una URL que se cambia en un sitio
/// y se olvida en otro deja al usuario ante un enlace roto justo en la pantalla
/// donde acepta condiciones.
class DocumentosLegales {
  static const terminos =
      'https://legacynetworkco.com/terminos-y-condiciones-de-uso-app-legacy/';

  static const privacidad = 'https://legacynetworkco.com/politica-de-privacidad/';
}

/// Abre un documento legal en el navegador. Devuelve `false` si no se pudo, para
/// que quien llame lo diga en pantalla en lugar de dejar un toque sin respuesta.
Future<bool> abrirDocumentoLegal(String url) async {
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
