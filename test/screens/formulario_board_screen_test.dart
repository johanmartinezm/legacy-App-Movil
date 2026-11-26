import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/data/services/board_formularios_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/legacy_board/formulario_board_screen.dart';
import 'package:provider/provider.dart';

/// El motor de formularios de Legacy Board, con un formulario de dos secciones
/// servido por un backend falso.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Map<String, dynamic> formulario({Map<String, dynamic>? envio, bool permiteNuevo = false}) => {
        'clave': 'A',
        'permite_nuevo': permiteNuevo,
        'titulo': 'Postulación como consejero',
        'descripcion': 'Cuéntanos tu trayectoria.',
        'texto_terminos': 'Acepto los términos.',
        'texto_confirmacion': 'Recibimos tu postulación.',
        'envio_actual': envio,
        'secciones': [
          {
            'titulo': 'Identificación',
            'campos': [
              {'clave': 'nombre_completo', 'etiqueta': 'Nombre completo', 'tipo': 'texto', 'obligatorio': true, 'max_largo': 120},
              {'clave': 'linkedin', 'etiqueta': 'Perfil de LinkedIn', 'tipo': 'url', 'dominio': 'linkedin.com'},
            ],
          },
          {
            'titulo': 'Experiencia',
            'campos': [
              {
                'clave': 'sectores',
                'etiqueta': 'Sectores',
                'tipo': 'multiseleccion',
                'obligatorio': true,
                'opciones': [
                  {'id': 's1', 'codigo': 'salud', 'etiqueta': 'Salud'},
                  {'id': 's2', 'codigo': 'agro', 'etiqueta': 'Agro'},
                ],
              },
              {'clave': 'fue_independiente', 'etiqueta': '¿Ha sido independiente?', 'tipo': 'sino', 'obligatorio': true},
            ],
          },
        ],
      };

  http.Response json(Object cuerpo, int status) =>
      http.Response.bytes(utf8.encode(jsonEncode(cuerpo)), status, headers: {'content-type': 'application/json'});

  Future<void> montar(WidgetTester tester, MockClient cliente) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        home: FormularioBoardScreen(clave: 'A', servicio: BoardFormulariosService(client: cliente)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('sin el plus explica que es solo para Legacy+', (tester) async {
    await montar(tester, MockClient((_) async => http.Response('Esta sección es para usuarios Legacy+.', 403)));
    expect(find.text('Solo para usuarios Legacy+'), findsOneWidget);
    expect(find.byKey(const Key('board-siguiente')), findsNothing);
  });

  testWidgets('si ya lo envió, muestra el estado y no el formulario', (tester) async {
    await montar(
      tester,
      MockClient((_) async => json(
            formulario(envio: {'id': 'e1', 'formulario': 'A', 'estado': 'aprobada', 'creado_en': '2026-11-20T10:00:00Z'}),
            200,
          )),
    );
    expect(find.textContaining('Ya enviaste este formulario'), findsOneWidget);
    expect(find.text('Aprobada'), findsOneWidget);
    expect(find.byKey(const Key('board-nombre_completo')), findsNothing);
  });

  testWidgets('de punta a punta: valida cada paso, envía y confirma', (tester) async {
    Map<String, dynamic>? enviado;
    await montar(
      tester,
      MockClient((r) async {
        if (r.method == 'POST') {
          enviado = jsonDecode(r.body) as Map<String, dynamic>;
          return json({'id': 'e1', 'formulario': 'A', 'estado': 'pendiente'}, 201);
        }
        return json(formulario(), 200);
      }),
    );

    expect(find.text('Paso 1 de 2'), findsOneWidget);
    // Sin el nombre no avanza.
    await tester.tap(find.byKey(const Key('board-siguiente')));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(find.text('Paso 1 de 2'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('board-nombre_completo')), '  Ana   Pérez ');
    await tester.enterText(find.byKey(const Key('board-linkedin')), 'https://evil.co/ana');
    await tester.tap(find.byKey(const Key('board-siguiente')));
    await tester.pumpAndSettle();
    expect(find.text('Debe ser un enlace de linkedin.com'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('board-linkedin')), '');
    await tester.tap(find.byKey(const Key('board-siguiente')));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 2'), findsOneWidget);

    await tester.tap(find.text('Salud'));
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    // Sin aceptar los términos no sale.
    await tester.tap(find.byKey(const Key('board-siguiente')));
    await tester.pumpAndSettle();
    expect(find.text('Debes aceptar para enviar'), findsOneWidget);
    expect(enviado, isNull);

    await tester.tap(find.byKey(const Key('board-acepta-terminos')));
    await tester.tap(find.byKey(const Key('board-siguiente')));
    await tester.pumpAndSettle();

    expect(enviado, {
      'respuestas': {
        'nombre_completo': 'Ana Pérez',
        'sectores': ['s1'],
        'fue_independiente': false,
      },
      'acepta_terminos': true,
    });
    expect(find.text('Recibimos tu postulación.'), findsOneWidget);
    expect(find.text('En revisión'), findsOneWidget);
  });

  testWidgets('con una solicitud ya decidida del B, deja empezar otra', (tester) async {
    await montar(
      tester,
      MockClient((_) async => json(
            formulario(
              envio: {'id': 'b1', 'formulario': 'B', 'estado': 'rechazada', 'creado_en': '2026-11-20T10:00:00Z'},
              permiteNuevo: true,
            ),
            200,
          )),
    );
    expect(find.textContaining('Tu última solicitud'), findsOneWidget);
    expect(find.text('No aprobada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('board-nueva-solicitud')));
    await tester.pumpAndSettle();
    expect(find.text('Paso 1 de 2'), findsOneWidget);
  });

  testWidgets('con una solicitud pendiente del B, solo se ve el estado', (tester) async {
    await montar(
      tester,
      MockClient((_) async => json(
            formulario(envio: {'id': 'b1', 'formulario': 'B', 'estado': 'pendiente'}, permiteNuevo: true),
            200,
          )),
    );
    expect(find.text('En revisión'), findsOneWidget);
    expect(find.byKey(const Key('board-nueva-solicitud')), findsNothing);
  });

  testWidgets('si el backend rechaza un campo, vuelve a su sección y lo marca', (tester) async {
    await montar(
      tester,
      MockClient((r) async => r.method == 'POST'
          ? json({'message': 'Nombre completo: trae caracteres inválidos', 'campo': 'nombre_completo'}, 400)
          : json(formulario(), 200)),
    );
    await tester.enterText(find.byKey(const Key('board-nombre_completo')), 'Ana');
    await tester.tap(find.byKey(const Key('board-siguiente')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agro'));
    await tester.tap(find.text('Sí'));
    await tester.tap(find.byKey(const Key('board-acepta-terminos')));
    await tester.tap(find.byKey(const Key('board-siguiente')));
    await tester.pumpAndSettle();

    expect(find.text('Paso 1 de 2'), findsOneWidget);
    // Una vez en el campo y otra en el aviso inferior.
    expect(find.text('Nombre completo: trae caracteres inválidos'), findsNWidgets(2));
    // Lo escrito se conserva.
    expect(find.text('Ana'), findsOneWidget);
  });
}
