/// Que clase de cosa se encontro. Decide el icono, el nombre de la seccion y
/// —en el delegate— a que pantalla se navega.
enum TipoResultado { contenido, evento, programa, sinergia, miembro }

/// Un resultado de la busqueda global, venga de donde venga.
///
/// `origen` guarda el objeto original (ContentItem, EventModel, GraphqlProgram,
/// Synergy o UserModel) porque cada pantalla de detalle lo recibe como `extra`
/// de go_router. Aqui no se navega: de eso se encarga quien pinta la lista, que
/// es el unico que tiene el BuildContext.
class ResultadoBusqueda {
  final TipoResultado tipo;
  final String titulo;
  final String subtitulo;
  final Object origen;

  /// Texto contra el que se busca, ya normalizado (minusculas y sin tildes).
  /// Se calcula una vez al construir y no en cada pulsacion de tecla: la lista
  /// se recorre entera con cada letra que se escribe.
  final String textoBuscable;

  ResultadoBusqueda({
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.origen,
    required this.textoBuscable,
  });

  static const Map<TipoResultado, String> nombresDeSeccion = {
    TipoResultado.contenido: 'Contenido',
    TipoResultado.evento: 'Eventos',
    TipoResultado.programa: 'Programas',
    TipoResultado.sinergia: 'Sinergias',
    TipoResultado.miembro: 'Miembros',
  };
}
