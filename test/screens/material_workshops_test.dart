import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/domain/models/event_model.dart';
import 'package:legacy_app/domain/models/workshop_model.dart';
import 'package:legacy_app/presentation/widgets/eventos/material_workshops.dart';

/// Parte A del plan de workshops: el detalle del evento muestra el material de
/// cada workshop cuando ese workshop termina.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
    await initializeDateFormatting('es');
  });

  final ahora = DateTime.parse('2026-12-10T12:00:00-05:00');

  Map<String, dynamic> ws(
    String id,
    String desde,
    String hasta, [
    Map<String, dynamic>? material,
  ]) => {
    'id': id,
    'eventId': 'ev-1',
    'name': 'Workshop $id',
    'room': 'Sala',
    'speaker': 'Ponente',
    'startDateTime': '2026-12-10T$desde:00-05:00',
    'endDateTime': '2026-12-10T$hasta:00-05:00',
    'material': material,
  };

  final completo = {
    'imageUrl': '',
    'fileName': '0f8fad5b-d9cb-469f-a165-70867728950e_Guia.pdf',
    'fileOriginalName': 'Guía del workshop.pdf',
    'fileSize': 2 * 1024 * 1024,
    'videoUrl': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  };

  EventModel evento(List<Map<String, dynamic>> workshops) =>
      EventModel.fromJson({
        'id': 'ev-1',
        'title': 'Evento',
        'date': '2026-12-10T00:00:00Z',
        'isFree': true,
        'workshops': workshops,
      });

  Future<void> montar(WidgetTester tester, EventModel e) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SingleChildScrollView(
            child: MaterialWorkshops(event: e, ahora: ahora),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('solo los workshops que ya terminaron y tienen material', () {
    final e = evento([
      ws('termino', '09:00', '10:00', completo),
      ws('en-curso', '11:30', '12:30', completo),
      ws('sin-material', '08:00', '09:00'),
    ]);
    final lista = MaterialWorkshops.conMaterial(e, ahora: ahora);
    expect(lista.map((w) => w.id), ['termino']);
  });

  testWidgets('sin material terminado, la sección no aparece', (tester) async {
    await montar(tester, evento([ws('en-curso', '11:30', '12:30', completo)]));
    expect(find.byKey(const Key('material-workshops')), findsNothing);
  });

  testWidgets('archivo para descargar y video de YouTube dentro de la app', (
    tester,
  ) async {
    await montar(tester, evento([ws('a', '09:00', '10:00', completo)]));

    expect(find.text('Material de los workshops'), findsOneWidget);
    expect(find.text('Descargar'), findsOneWidget);
    expect(find.text('Guía del workshop.pdf · 2.0 MB'), findsOneWidget);
    expect(find.text('Ver video'), findsOneWidget);
    expect(find.text('Se abre fuera de la app'), findsNothing);
  });

  testWidgets('Vimeo se abre fuera de la app', (tester) async {
    await montar(
      tester,
      evento([
        ws('v', '09:00', '10:00', {
          'videoUrl': 'https://vimeo.com/123456789/abc',
        }),
      ]),
    );
    expect(find.text('Ver video en Vimeo'), findsOneWidget);
    expect(find.text('Se abre fuera de la app'), findsOneWidget);
    expect(find.text('Descargar'), findsNothing);
  });

  test('la descarga apunta a /api/documents con el nombre del servidor', () {
    expect(
      urlDeDescarga('uuid_Guía final.pdf'),
      endsWith('/api/documents/uuid_Gu%C3%ADa%20final.pdf'),
    );
  });

  test('el material se lee del JSON y vacío es «no hay»', () {
    final w = WorkshopModel.fromJson(ws('a', '09:00', '10:00', completo));
    expect(w.material.esYoutube, isTrue);
    expect(w.material.fileSize, 2 * 1024 * 1024);
    expect(
      WorkshopModel.fromJson(ws('b', '09:00', '10:00')).material.vacio,
      isTrue,
    );
  });
}
