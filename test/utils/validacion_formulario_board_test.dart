import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/data/services/board_formularios_service.dart';
import 'package:legacy_app/domain/utils/validacion_formulario_board.dart';

/// Las reglas del formulario en la app deben coincidir con las del backend
/// (board_formulario_service.go). Estos casos son los mismos que prueba Go.
void main() {
  const opciones = [
    OpcionFormularioBoard(id: 'o1', codigo: 'junta_directiva', etiqueta: 'Junta directiva'),
    OpcionFormularioBoard(id: 'o2', codigo: 'no_aplica', etiqueta: 'No aplica'),
  ];

  CampoBoard campo(String tipo,
          {bool obligatorio = true, int? min, int? max, int maxLargo = 0, String patron = '', String dominio = ''}) =>
      CampoBoard(
        clave: 'c',
        etiqueta: 'Campo',
        tipo: tipo,
        obligatorio: obligatorio,
        min: min,
        max: max,
        maxLargo: maxLargo,
        patron: patron,
        dominio: dominio,
        exclusiva: 'no_aplica',
        opciones: opciones,
      );

  test('obligatorio: vacío, en blanco y lista vacía fallan; opcional vacío pasa', () {
    expect(validarCampoBoard(campo(TipoCampoBoard.texto), null), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.texto), '   '), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.multiseleccion), <String>[]), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.texto, obligatorio: false), ''), isNull);
  });

  test('textos: largo máximo y patrón', () {
    expect(validarCampoBoard(campo(TipoCampoBoard.textoLargo, maxLargo: 600), 'a' * 600), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.textoLargo, maxLargo: 600), 'a' * 601), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.texto), 'a' * 201), isNotNull, reason: '200 por defecto');
    final doc = campo(TipoCampoBoard.texto, patron: r'^[A-Za-z0-9.\- ]+$');
    expect(validarCampoBoard(doc, '1.020.304'), isNull);
    expect(validarCampoBoard(doc, '123;DROP'), isNotNull);
  });

  test('correo y teléfono', () {
    expect(validarCampoBoard(campo(TipoCampoBoard.email), 'ana@empresa.co'), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.email), 'ana@'), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.email), 'Ana <ana@x.co>'), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.telefono), '+57 300 123 4567'), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.telefono), '123'), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.telefono), '+57 300 ABC 4567'), isNotNull);
  });

  test('números en rango', () {
    final anios = campo(TipoCampoBoard.numero, min: 0, max: 60);
    expect(validarCampoBoard(anios, 20), isNull);
    expect(validarCampoBoard(anios, 0), isNull);
    expect(validarCampoBoard(anios, 61), isNotNull);
  });

  test('LinkedIn: esquema y dominio', () {
    final li = campo(TipoCampoBoard.url, dominio: 'linkedin.com');
    expect(validarCampoBoard(li, 'https://www.linkedin.com/in/ana'), isNull);
    expect(validarCampoBoard(li, 'linkedin.com/in/ana'), isNotNull);
    expect(validarCampoBoard(li, 'https://linkedin.com.evil.co/in/ana'), isNotNull);
  });

  test('fecha: ni futura ni mal escrita', () {
    final hoy = DateTime(2026, 11, 25);
    expect(validarCampoBoard(campo(TipoCampoBoard.fecha), '1975-04-30', hoy: hoy), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.fecha), '2030-01-01', hoy: hoy), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.fecha), '01/02/1980', hoy: hoy), isNotNull);
  });

  test('selección: solo opciones del campo; «No aplica» va sola', () {
    expect(validarCampoBoard(campo(TipoCampoBoard.seleccion), 'o1'), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.seleccion), 'otra'), isNotNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.multiseleccion), ['o2']), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.multiseleccion), ['o1', 'o2']), contains('No aplica'));
  });

  test('sí/no y foto', () {
    expect(validarCampoBoard(campo(TipoCampoBoard.siNo), false), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.foto), '/api/images/x.jpg'), isNull);
    expect(validarCampoBoard(campo(TipoCampoBoard.foto), 'https://evil.co/x.jpg'), isNotNull);
  });

  test('respuestas para enviar: normaliza y deja fuera lo vacío', () {
    final f = FormularioBoard(clave: 'A', titulo: 'A', secciones: [
      SeccionBoard(titulo: 'S', campos: [
        const CampoBoard(clave: 'nombre', etiqueta: 'N', tipo: TipoCampoBoard.texto),
        const CampoBoard(clave: 'texto', etiqueta: 'T', tipo: TipoCampoBoard.textoLargo),
        const CampoBoard(clave: 'vacio', etiqueta: 'V', tipo: TipoCampoBoard.texto),
        const CampoBoard(clave: 'lista', etiqueta: 'L', tipo: TipoCampoBoard.multiseleccion),
        const CampoBoard(clave: 'anios', etiqueta: 'A', tipo: TipoCampoBoard.numero),
      ]),
    ]);
    final r = respuestasParaEnviarBoard(f, {
      'nombre': '  Ana   Pérez ',
      'texto': '  Uno.\nDos. ',
      'vacio': '   ',
      'lista': <String>[],
      'anios': '20',
      'ajeno': 'no viaja',
    });
    expect(r, {'nombre': 'Ana Pérez', 'texto': 'Uno.\nDos.', 'anios': 20});
    expect(seccionDelCampoBoard(f, 'anios'), 0);
    expect(seccionDelCampoBoard(f, 'nada'), -1);
  });
}
