import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/resultado_busqueda.dart';
import 'package:legacy_app/domain/utils/busqueda_global.dart';

ResultadoBusqueda _r(TipoResultado tipo, String titulo, {String extra = ''}) => ResultadoBusqueda(
      tipo: tipo,
      titulo: titulo,
      subtitulo: '',
      origen: titulo,
      textoBuscable: normalizar('$titulo $extra'),
    );

void main() {
  final catalogo = [
    _r(TipoResultado.contenido, 'Planificación patrimonial', extra: 'artículo sobre herencia'),
    _r(TipoResultado.evento, 'LEGACY SUMMIT 2026: Liderazgo y Trascendencia', extra: 'Cancún'),
    _r(TipoResultado.evento, 'Sesión de bienvenida Legacy Network', extra: 'Bogotá'),
    _r(TipoResultado.programa, 'Gobierno Corporativo', extra: 'Diplomado en línea'),
    _r(TipoResultado.sinergia, 'Busco socio para exportar café', extra: 'Alianzas'),
    _r(TipoResultado.miembro, 'María Gómez', extra: 'Directora Financiera Andina SAS'),
  ];

  group('normalizar', () {
    test('quita tildes y pasa a minúsculas', () {
      expect(normalizar('Sesión de Bienvenida'), 'sesion de bienvenida');
      expect(normalizar('María Gómez'), 'maria gomez');
      expect(normalizar('CANCÚN'), 'cancun');
      expect(normalizar('Diseño Ñandú'), 'diseno nandu');
    });
  });

  group('filtrar', () {
    test('encuentra sin escribir la tilde', () {
      // Es el caso que motiva todo esto: en un teclado móvil nadie escribe
      // "Sesión" con tilde.
      final r = filtrar(catalogo, 'sesion');
      expect(r, hasLength(1));
      expect(r.first.titulo, contains('Sesión'));
    });

    test('encuentra escribiendo la tilde igualmente', () {
      expect(filtrar(catalogo, 'sesión'), hasLength(1));
    });

    test('busca también fuera del título', () {
      // "Cancún" está en el lugar del evento, no en su nombre.
      final r = filtrar(catalogo, 'cancun');
      expect(r, hasLength(1));
      expect(r.first.tipo, TipoResultado.evento);
    });

    test('varias palabras en cualquier orden', () {
      // Buscar la frase entera como una sola cadena fallaría aquí.
      expect(filtrar(catalogo, 'liderazgo summit'), hasLength(1));
      expect(filtrar(catalogo, 'summit liderazgo'), hasLength(1));
    });

    test('exige que estén todas las palabras', () {
      expect(filtrar(catalogo, 'summit bogota'), isEmpty);
    });

    test('una consulta vacía o de espacios no devuelve nada', () {
      // Devolver el catálogo entero al abrir la lupa sería ruido, no ayuda.
      expect(filtrar(catalogo, ''), isEmpty);
      expect(filtrar(catalogo, '   '), isEmpty);
    });

    test('alcanza las cinco fuentes, no solo contenido', () {
      // Es justo lo que no hacía antes: la búsqueda solo miraba el contenido.
      expect(filtrar(catalogo, 'legacy').map((r) => r.tipo), contains(TipoResultado.evento));
      expect(filtrar(catalogo, 'gobierno').single.tipo, TipoResultado.programa);
      expect(filtrar(catalogo, 'cafe').single.tipo, TipoResultado.sinergia);
      expect(filtrar(catalogo, 'maria').single.tipo, TipoResultado.miembro);
      expect(filtrar(catalogo, 'herencia').single.tipo, TipoResultado.contenido);
    });

    test('encuentra a una persona por su empresa o su cargo', () {
      expect(filtrar(catalogo, 'andina').single.titulo, 'María Gómez');
      expect(filtrar(catalogo, 'financiera').single.titulo, 'María Gómez');
    });
  });

  group('agrupar', () {
    test('respeta el orden de los tipos y omite los vacíos', () {
      final agrupados = agrupar(filtrar(catalogo, 'legacy'));
      expect(agrupados.keys, everyElement(isNot(TipoResultado.programa)));
      // El orden debe ser estable entre búsquedas: si no, las secciones bailan.
      final orden = agrupados.keys.toList();
      final esperado = TipoResultado.values.where(orden.contains).toList();
      expect(orden, esperado);
    });

    test('mete cada resultado en su sección', () {
      final agrupados = agrupar(catalogo);
      expect(agrupados[TipoResultado.evento], hasLength(2));
      expect(agrupados[TipoResultado.miembro], hasLength(1));
    });
  });
}
