import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/data/services/custom_content_service.dart';
import 'package:legacy_app/data/services/event_service.dart';
import 'package:legacy_app/domain/models/content_model.dart';
import 'package:legacy_app/domain/models/custom_content_model.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/utils/notificacion_destino.dart';

/// Devuelve siempre el mismo evento, o revienta si se le pide.
class _EventosFalsos extends EventService {
  final EventModel? evento;
  final bool falla;
  String? idPedido;

  _EventosFalsos({this.evento, this.falla = false});

  @override
  Future<EventModel> getEventDetails(String id) async {
    idPedido = id;
    if (falla) throw Exception('sin red');
    return evento!;
  }
}

class _ContenidosFalsos extends CustomContentService {
  final CustomContent? contenido;
  final bool falla;

  _ContenidosFalsos({this.contenido, this.falla = false});

  @override
  Future<CustomContent?> getCustomContentById(String id) async {
    if (falla) throw Exception('sin red');
    return contenido;
  }
}

EventModel _evento(String id) => EventModel(
  id: id,
  title: 'Cumbre de gobierno corporativo',
  category: 'Eventos',
  date: '2026-09-01',
  priceLabel: 'Gratis',
  price: 0,
  isFree: true,
  buttonText: 'Inscribirme',
  actionStatus: 'available',
  imageUrl: '',
  description: '',
);

CustomContent _contenido(String id, CustomContentType tipo) => CustomContent(
  id: id,
  type: tipo,
  title: 'Sucesión y patrimonio',
  excerpt: '',
  bodyText: '',
  videoUrl: 'https://ejemplo.test/v.mp4',
  thumbnailUrl: '',
  isPublished: true,
);

/// Cubre el salto desde una notificación a la novedad que la originó. Se prueba
/// aquí y no a mano porque reproducirlo exige enviar push reales a un teléfono.
void main() {
  group('lo que el backend manda de verdad', () {
    test('un evento abre su detalle con el evento ya resuelto', () async {
      final servicio = _EventosFalsos(evento: _evento('ev-7'));

      final destino = await resolverNovedad(
        {'type': 'event', 'id': 'ev-7'},
        eventService: servicio,
      );

      expect(destino.ruta, '/evento');
      expect(servicio.idPedido, 'ev-7');
      // La pantalla recibe la entidad, no el id: si llegara un id, el cast de
      // state.extra tumbaría la app al abrirse.
      expect(destino.extra, isA<EventModel>());
      expect((destino.extra as EventModel).id, 'ev-7');
    });

    test('un contenido de vídeo abre el reproductor', () async {
      final destino = await resolverNovedad(
        {'type': 'content', 'id': 'c-1'},
        contentService: _ContenidosFalsos(
          contenido: _contenido('c-1', CustomContentType.video),
        ),
      );

      expect(destino.ruta, '/video-detail');
      expect((destino.extra as ContentItem).type, 'video');
    });

    test('un contenido de texto abre el artículo', () async {
      final destino = await resolverNovedad(
        {'type': 'content', 'id': 'c-2'},
        contentService: _ContenidosFalsos(
          contenido: _contenido('c-2', CustomContentType.text),
        ),
      );

      expect(destino.ruta, '/article-detail');
      expect((destino.extra as ContentItem).id, 'c-2');
    });

    test('un mensaje de chat abre esa conversación', () async {
      final destino = await resolverNovedad({
        'type': 'chat',
        'id': 'conexion-3',
        'title': 'Juan Pérez',
      });

      // La pantalla recibe el id por la ruta y el nombre por query, que es como
      // está declarada `/individual-chat/:id` en main.dart.
      expect(destino.ruta, '/individual-chat/conexion-3?title=Juan%20P%C3%A9rez');
      expect(destino.extra, isNull);
    });

    test('un chat sin nombre de quien escribe abre igual', () async {
      // Si el remitente no tiene nombre legible, perder el encabezado no puede
      // costar el acceso a la conversación.
      final destino = await resolverNovedad({'type': 'chat', 'id': 'c-1'});

      expect(destino.ruta, '/individual-chat/c-1?title=Chat');
    });

    test('los datos llegan como texto y aun así se leen', () async {
      // FCM entrega el data como Map<String, dynamic> con valores string.
      final destino = await resolverNovedad(
        {'type': 'event', 'id': '42'},
        eventService: _EventosFalsos(evento: _evento('42')),
      );

      expect(destino.ruta, '/evento');
    });
  });

  group('cuando no se puede abrir la novedad, se abre la bandeja', () {
    test('sin datos', () async {
      expect((await resolverNovedad({})).ruta, '/notifications');
    });

    test('con id vacío', () async {
      final destino = await resolverNovedad({'type': 'event', 'id': ''});
      expect(destino.ruta, '/notifications');
    });

    test('con un tipo que esta versión no conoce', () async {
      // Un backend más nuevo puede mandar tipos que esta app aún no maneja.
      final destino = await resolverNovedad({'type': 'sinergia', 'id': 's-1'});
      expect(destino.ruta, '/notifications');
      expect(destino.extra, isNull);
    });

    test('si el contenido ya no existe', () async {
      final destino = await resolverNovedad(
        {'type': 'content', 'id': 'borrado'},
        contentService: _ContenidosFalsos(contenido: null),
      );
      expect(destino.ruta, '/notifications');
    });

    test('si la carga del evento falla', () async {
      final destino = await resolverNovedad(
        {'type': 'event', 'id': 'ev-9'},
        eventService: _EventosFalsos(falla: true),
      );
      expect(destino.ruta, '/notifications');
    });

    test('si la carga del contenido falla', () async {
      final destino = await resolverNovedad(
        {'type': 'content', 'id': 'c-9'},
        contentService: _ContenidosFalsos(falla: true),
      );
      expect(destino.ruta, '/notifications');
    });
  });
}
