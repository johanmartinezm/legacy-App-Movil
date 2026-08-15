import 'package:go_router/go_router.dart';

import '../../data/services/custom_content_service.dart';
import '../../data/services/event_service.dart';

/// A dónde lleva una notificación: la ruta y lo que la pantalla necesita.
class DestinoNovedad {
  final String ruta;
  final Object? extra;

  const DestinoNovedad(this.ruta, {this.extra});
}

/// La bandeja de notificaciones, que es el destino cuando no se puede abrir la
/// novedad concreta.
const destinoBandeja = DestinoNovedad('/notifications');

/// Traduce el `{type, id}` de una notificación a la pantalla que le corresponde.
///
/// El backend manda `{"type": "event", "id": ...}` al publicar un evento y
/// `{"type": "content", "id": ...}` al publicar contenido
/// (`handler/http/avisos.go`), y `{"type": "chat", "id": id de la conexión,
/// "title": quién escribe}` al llegar un mensaje
/// (`core/services/chat_avisos.go`). La app los recibía y los ignoraba: tocar
/// cualquier notificación abría la bandeja, no la novedad.
///
/// **Hay que resolver el objeto antes de navegar.** Las pantallas de detalle
/// reciben la entidad entera por `extra` —no un id—, así que empujar la ruta
/// con lo que trae la notificación reventaría en el cast de `state.extra`.
///
/// Cuando algo falla —sin red, contenido borrado, un `type` que esta versión de
/// la app todavía no conoce— devuelve la bandeja, que es lo que se hacía antes.
/// Nunca deja de abrir algo.
Future<DestinoNovedad> resolverNovedad(
  Map<String, dynamic> datos, {
  EventService? eventService,
  CustomContentService? contentService,
}) async {
  final tipo = datos['type']?.toString();
  final id = datos['id']?.toString();

  if (tipo == null || id == null || id.isEmpty) return destinoBandeja;

  try {
    switch (tipo) {
      case 'chat':
        // El chat es el único destino que no necesita red: la ruta lleva el id
        // de la conexión y la pantalla carga el historial al abrirse. Por eso
        // funciona igual con la app recién arrancada y sin conexión todavía.
        //
        // El título viaja en la notificación porque `/individual-chat/:id` lo
        // espera como parámetro y resolverlo aquí obligaría a pedir la lista de
        // conversaciones entera solo para saber un nombre.
        final titulo = datos['title']?.toString().trim();
        final encabezado = (titulo == null || titulo.isEmpty) ? 'Chat' : titulo;
        return DestinoNovedad(
          '/individual-chat/${Uri.encodeComponent(id)}'
          '?title=${Uri.encodeComponent(encabezado)}',
        );

      case 'event':
        final evento = await (eventService ?? EventService()).getEventDetails(
          id,
        );
        return DestinoNovedad('/evento', extra: evento);

      case 'content':
        final contenido =
            await (contentService ?? CustomContentService())
                .getCustomContentById(id);
        if (contenido == null) return destinoBandeja;
        // El contenido propio y el de WordPress se pintan con las mismas
        // pantallas, y por eso se unifican en ContentItem.
        final item = contenido.toContentItem();
        return DestinoNovedad(
          item.type == 'video' ? '/video-detail' : '/article-detail',
          extra: item,
        );
    }
  } catch (_) {
    return destinoBandeja;
  }

  return destinoBandeja;
}

/// Resuelve el destino y navega hasta él.
Future<void> abrirNovedad(GoRouter router, Map<String, dynamic> datos) async {
  final destino = await resolverNovedad(datos);
  router.push(destino.ruta, extra: destino.extra);
}
