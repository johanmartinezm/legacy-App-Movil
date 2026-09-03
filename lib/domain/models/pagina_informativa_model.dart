/// Una página de información que se edita desde el panel administrativo.
///
/// La app no lleva el texto dentro: lo pide por `slug` a
/// `GET /api/paginas/{slug}` y lo pinta tal cual. Así cambiar una palabra no
/// exige publicar una versión nueva en las tiendas.
class PaginaInformativa {
  final String slug;
  final String titulo;
  final String subtitulo;
  final String imagenUrl;

  /// Texto corrido. Los párrafos se separan por una línea en blanco; la
  /// pantalla es la que decide cómo pintarlos.
  final String cuerpo;

  final DateTime? actualizadaEn;

  const PaginaInformativa({
    required this.slug,
    required this.titulo,
    this.subtitulo = '',
    this.imagenUrl = '',
    this.cuerpo = '',
    this.actualizadaEn,
  });

  factory PaginaInformativa.fromJson(Map<String, dynamic> json) {
    return PaginaInformativa(
      slug: json['slug']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      subtitulo: json['subtitulo']?.toString() ?? '',
      imagenUrl: json['imagen_url']?.toString() ?? '',
      cuerpo: json['cuerpo']?.toString() ?? '',
      actualizadaEn: DateTime.tryParse(json['actualizada_en']?.toString() ?? ''),
    );
  }

  /// Los párrafos ya separados, sin líneas en blanco de sobra. Se calcula aquí
  /// y no en la pantalla para poder probarlo sin montar widgets.
  List<String> get parrafos => cuerpo
      .split(RegExp(r'\n\s*\n'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
}
