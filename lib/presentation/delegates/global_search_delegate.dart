import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/content_model.dart';
import '../../domain/models/event_model.dart';
import '../../domain/models/program_model.dart';
import '../../domain/models/resultado_busqueda.dart';
import '../../domain/models/synergy_model.dart';
import '../../domain/utils/busqueda_global.dart';

/// La busqueda de la lupa. Sustituye a `ContentSearchDelegate`, que solo miraba
/// el contenido: el documento de alcance la llama "Busqueda Global" y ahora
/// tambien alcanza eventos, programas, sinergias y miembros.
class GlobalSearchDelegate extends SearchDelegate<ResultadoBusqueda?> {
  final List<ResultadoBusqueda> todo;

  GlobalSearchDelegate({required this.todo}) : super(searchFieldLabel: 'Buscar en Legacy');

  static const _fondo = Color(0xFF050B15);
  static const _tarjeta = Color(0xFF0B1A2E);
  static const _borde = Color(0xFF2A4A75);
  static const _apagado = Color(0xFF90A4BA);
  static const _dorado = Color(0xFFD9A74A);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: _fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B1A2E),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.questrial(color: _apagado),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.questrial(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _lista(context);

  @override
  Widget buildSuggestions(BuildContext context) => _lista(context);

  Widget _lista(BuildContext context) {
    if (query.trim().isEmpty) {
      return _aviso(
        Icons.search,
        'Busca en toda la app',
        'Contenido, eventos, programas, sinergias y miembros.',
      );
    }

    final agrupados = agrupar(filtrar(todo, query));

    if (agrupados.isEmpty) {
      return _aviso(
        Icons.search_off,
        'Sin resultados para "$query"',
        'Prueba con una palabra más corta o con otro término.',
      );
    }

    // Cabecera de seccion + sus resultados, en una sola lista para que el
    // desplazamiento sea continuo entre secciones.
    final filas = <Widget>[];
    agrupados.forEach((tipo, resultados) {
      filas.add(_cabecera(tipo, resultados.length));
      filas.addAll(resultados.map((r) => _tarjetaResultado(context, r)));
    });

    return Container(
      color: _fondo,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: filas,
      ),
    );
  }

  Widget _aviso(IconData icono, String titulo, String detalle) {
    return Container(
      color: _fondo,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: _apagado, size: 40),
              const SizedBox(height: 16),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: GoogleFonts.barlow(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: GoogleFonts.questrial(color: _apagado, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecera(TipoResultado tipo, int cuantos) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            ResultadoBusqueda.nombresDeSeccion[tipo]!.toUpperCase(),
            style: GoogleFonts.barlow(
              color: _dorado,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 8),
          Text('$cuantos', style: GoogleFonts.questrial(color: _apagado, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tarjetaResultado(BuildContext context, ResultadoBusqueda r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _tarjeta.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borde.withValues(alpha: 0.35), width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrir(context, r),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF132A44),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E3A5F).withValues(alpha: 0.4)),
                ),
                child: Icon(_icono(r), color: _dorado, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlow(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    if (r.subtitulo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        r.subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.questrial(fontSize: 12, color: _apagado),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icono(ResultadoBusqueda r) {
    switch (r.tipo) {
      case TipoResultado.evento:
        return Icons.calendar_month;
      case TipoResultado.programa:
        return Icons.school;
      case TipoResultado.sinergia:
        return Icons.handshake_outlined;
      case TipoResultado.miembro:
        return Icons.person_outline;
      case TipoResultado.contenido:
        final tipo = (r.origen as ContentItem).type.toLowerCase();
        if (tipo == 'video') return Icons.play_circle_outline;
        if (tipo == 'podcast') return Icons.headset;
        if (tipo == 'book' || tipo == 'libros') return Icons.book_outlined;
        return Icons.article_outlined;
    }
  }

  void _abrir(BuildContext context, ResultadoBusqueda r) {
    close(context, r);

    switch (r.tipo) {
      case TipoResultado.contenido:
        final item = r.origen as ContentItem;
        context.push(item.type.toLowerCase() == 'video' ? '/video-detail' : '/article-detail', extra: item);
      case TipoResultado.evento:
        context.push('/evento', extra: r.origen as EventModel);
      case TipoResultado.programa:
        context.push('/programa-detalle', extra: r.origen as GraphqlProgram);
      case TipoResultado.sinergia:
        context.push('/comite-sinergias/detalle', extra: r.origen as Synergy);
      case TipoResultado.miembro:
        // No hay pantalla de perfil de otra persona: el directorio es lo mas
        // cerca que se puede llevar a quien busca a alguien por su nombre.
        context.push('/comunidad-miembros');
    }
  }
}
