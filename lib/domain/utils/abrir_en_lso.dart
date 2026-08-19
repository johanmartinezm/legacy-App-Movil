import 'package:url_launcher/url_launcher.dart';

/// Abre la página de un producto en la tienda de LSO.
///
/// Programas y libros son de LSO: se publican en dólares y tienen su propio
/// proceso de compra, así que la app lleva a su página en vez de venderlos
/// dentro —donde el carrito los sumaba como pesos y les aplicaba IVA
/// colombiano—. Decisión del cliente del 2026-08-19.
///
/// Se abre **fuera** de la app a propósito: la compra pide cuenta en LSO y
/// medios de pago que la app no tiene, así que conviene la sesión del navegador
/// de verdad.
///
/// Devuelve `false` si no se pudo abrir —o si el producto llegó sin enlace—
/// para que la pantalla lo diga en lugar de dejar un toque sin respuesta.
Future<bool> abrirEnLso(String? url) async {
  if (url == null || url.trim().isEmpty) return false;
  final uri = Uri.parse(url.trim());
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Lo que se le dice a alguien cuando el enlace no abre. Nombra el sitio para
/// que pueda buscarlo a mano.
const mensajeLsoNoAbre =
    'No pudimos abrir la página en la tienda. Está en lso.school.';
