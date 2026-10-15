import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/models/program_model.dart';
import '../../../data/services/graphql_service.dart';
import '../../../data/services/secciones_inicio_service.dart';
import '../../widgets/boton_volver.dart';
import 'package:legacy_app/config/theme/app_theme.dart';

/// Un programa tal como lo pide el cliente: el título que se muestra y la
/// página de LSO a la que lleva.
class ProgramaLso {
  final String titulo;
  final String enlace;
  const ProgramaLso(this.titulo, this.enlace);
}

/// Programas de LSO en dos secciones fijas, con los títulos y enlaces que
/// entregó el cliente el 2026-10-15.
///
/// Los títulos y enlaces mandan aquí, no la tienda: en `lso.school/graphql`
/// varios tienen otro nombre («Certificación en Gobierno Corporativo»), uno no
/// existe como producto (consultores) y los de actualización no tienen página
/// propia, todos viven en /programas-de-actualizacion/. De la tienda solo se
/// toman la imagen y el precio cuando el producto existe ([armarProgramas]).
const List<ProgramaLso> programasPrincipales = [
  ProgramaLso(
    'Programa de Formación para Familias Empresarias y Propietarios',
    'https://lso.school/programas/propietarios-y-familias-empresarias/',
  ),
  ProgramaLso(
    'Certificación Internacional en Gobierno Corporativo',
    'https://lso.school/programas/certificacion-en-gobierno-corporativo/',
  ),
  ProgramaLso(
    'Programa de Formación de Consultores en Empresa Familiar',
    'https://lso.school/programas/consultores-en-empresa-familiar/',
  ),
  ProgramaLso(
    'Programa Ejecutivo de Gobierno Corporativo para Empresas de Seguros',
    'https://lso.school/programas/ejecutivo-de-gobierno-corporativo-para-empresas-de-seguros/',
  ),
];

const String _paginaActualizacion = 'https://lso.school/programas-de-actualizacion/';

const List<ProgramaLso> programasActualizacion = [
  ProgramaLso('Juntas, consejos y directorios que crean valor', _paginaActualizacion),
  ProgramaLso('Gestión del riesgo cambiario: conceptos y herramientas', _paginaActualizacion),
  ProgramaLso('Gestión Patrimonial y Valoración de Empresas', _paginaActualizacion),
  ProgramaLso('Gestión de Conflictos en la Empresa Familiar', _paginaActualizacion),
  ProgramaLso(
    'Board Branding: marca personal y posicionamiento para juntas directivas',
    _paginaActualizacion,
  ),
];

String _normalizar(String texto) {
  var t = texto.trim().toLowerCase();
  while (t.endsWith('/')) {
    t = t.substring(0, t.length - 1);
  }
  return t;
}

/// Una tarjeta por programa de [lista], en su orden, **siempre**: con o sin
/// tienda. El producto de la tienda se busca por su enlace y, si no, por su
/// título; si aparece, aporta imagen y precio. El enlace de la página general
/// de actualización no identifica a ningún producto, así que esos se buscan
/// solo por título.
///
/// Devuelve también si cada uno está en la tienda: sin producto no hay precio
/// que mostrar, y «Cotización» diría algo que no se sabe.
List<(GraphqlProgram, bool)> armarProgramas(
  List<GraphqlProgram> tienda,
  List<ProgramaLso> lista,
) {
  GraphqlProgram? buscar(ProgramaLso p) {
    final enlace = _normalizar(p.enlace);
    final titulo = _normalizar(p.titulo);
    for (final t in tienda) {
      if (enlace != _normalizar(_paginaActualizacion) && _normalizar(t.url ?? '') == enlace) {
        return t;
      }
    }
    for (final t in tienda) {
      if (_normalizar(t.name) == titulo) return t;
    }
    return null;
  }

  return [
    for (final p in lista)
      () {
        final producto = buscar(p);
        return (
          GraphqlProgram(
            id: producto?.id ?? p.enlace,
            name: p.titulo,
            url: p.enlace,
            imageUrl: producto?.imageUrl,
            price: producto?.price,
          ),
          producto != null,
        );
      }(),
  ];
}

class ProgramsScreen extends StatefulWidget {
  /// Se inyecta en las pruebas; por defecto, el real.
  final SeccionesInicioService? seccionesService;

  const ProgramsScreen({super.key, this.seccionesService});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  /// Lo que devolvió la tienda de LSO; vacío hasta que responde o si falla.
  /// Las tarjetas se pintan igual: solo pierden imagen y precio.
  List<GraphqlProgram> _tienda = const [];
  bool _isLoading = true;

  /// Título y texto del encabezado y del banner que el panel cambia («Textos
  /// de LSO»). Vacío hasta que responde el backend, o si falla: entonces se
  /// pintan los de siempre.
  Map<String, SeccionInicio> _textos = const {};

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
    _cargarTextos();
  }

  Future<void> _cargarTextos() async {
    final textos =
        await (widget.seccionesService ?? SeccionesInicioService()).secciones();
    if (mounted && textos.isNotEmpty) setState(() => _textos = textos);
  }

  String _titulo(String slug, String porDefecto) =>
      _textos[slug]?.titulo ?? porDefecto;

  String _texto(String slug, String porDefecto) =>
      _textos[slug]?.texto ?? porDefecto;

  Future<void> _fetchPrograms() async {
    try {
      // 32 programas hoy en la tienda; 50 deja margen sin tener que paginar.
      final todos = await GraphqlService().getPrograms(first: 50);

      if (mounted) {
        setState(() {
          _tienda = todos;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching programs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162540),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF183D6B),
              Color(0xFF183D6B),
              Color(0xFF162540),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera ──────────────────────────────────────────────────
              _buildHeader(context),

              // ── Contenido desplazable ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner hero
                      _buildHeroBanner(),
                      const SizedBox(height: 20),

                      // Entrada a la biblioteca.
                      //
                      // Va aquí por decisión del cliente (2026-08-20): los
                      // libros salen de la misma tienda que los programas, así
                      // que la sección de LSO es donde se buscan. Hasta hoy
                      // `/libros` **no tenía ninguna entrada**: la pantalla
                      // existía, funcionaba y solo se alcanzaba escribiéndole
                      // «libro» al asistente, que responde con un enlace
                      // interno.
                      _buildEntradaBiblioteca(context),
                      const SizedBox(height: 28),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: AppTheme.legacyActive),
                          ),
                        )
                      else ...[
                        _buildSeccion(
                          titulo: 'PROGRAMAS',
                          descripcion: null,
                          programas: armarProgramas(_tienda, programasPrincipales),
                        ),
                        const SizedBox(height: 28),
                        _buildSeccion(
                          titulo: 'PROGRAMAS DE ACTUALIZACIÓN',
                          descripcion: null,
                          programas: armarProgramas(_tienda, programasActualizacion),
                        ),
                        const SizedBox(height: 28),
                        _buildInCompany(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required String? descripcion,
    required List<(GraphqlProgram, bool)> programas,
  }) {
    if (programas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.barlow(
            color: AppTheme.legacyActive,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        if (descripcion != null) ...[
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: GoogleFonts.questrial(color: const Color(0xFF9FB2C2), fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        ...programas.map((p) => _ProgramRow(program: p.$1, enTienda: p.$2)),
      ],
    );
  }

  /// Sin producto propio en la tienda: es un servicio a medida, no algo que
  /// se compre con un clic. Lleva a Contáctenos, que ya existe.
  Widget _buildInCompany(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/contacto'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3156).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF306C9E).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.design_services_outlined, color: AppTheme.legacyActive, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programas in-company e in-family',
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diseñados a medida según las necesidades de su empresa o familia. Escríbanos para conversarlo.',
                    style: GoogleFonts.questrial(color: const Color(0xFF9FB2C2), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9FB2C2), size: 20),
          ],
        ),
      ),
    );
  }

  /// Fila que lleva a la biblioteca de LSO.
  ///
  /// Compacta a propósito: los libros acompañan a la formación, no compiten con
  /// ella, así que ocupa una línea y no una tarjeta como las de los programas.
  Widget _buildEntradaBiblioteca(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/libros'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3156).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF306C9E).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: AppTheme.legacyActive, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biblioteca',
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Los libros de LSO',
                    style: GoogleFonts.questrial(
                      color: const Color(0xFF9FB2C2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9FB2C2), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Cabecera con botón de retorno ──────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botón de retorno
          const BotonVolver(),
          const SizedBox(width: 14),

          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titulo('lso-encabezado', 'LSO · Legacy School of Ownership'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.barlow(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _texto('lso-encabezado', 'La escuela del propietario en LATAM'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.questrial(
                    fontSize: 12,
                    color: const Color(0xFF9FB2C2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner hero ────────────────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3156).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF306C9E).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titulo('lso-banner', 'Formación que los MBA no dan'),
            style: GoogleFonts.barlow(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _texto(
              'lso-banner',
              'Programas para gobernar la empresa y proteger el patrimonio. '
                  'Doble certificación LSO + EUDE ⭐, con contenido académico de '
                  'Harvard Business Impact. Alumni LSO acceden a Legacy+ con precio especial.',
            ),
            style: GoogleFonts.questrial(
              fontSize: 13,
              color: const Color(0xFF9FB2C2),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de programa ────────────────────────────────────────────────────────
//
// A diferencia de la tarjeta anterior, tocar esta fila no abre una pantalla
// de detalle dentro de la app: va directo a la página de pago en lso.school.
// Decisión del cliente (revisión de Diana Uribe, 22-08-2026): el detalle
// interno no traía suficiente información para convencer de comprar, pero sí
// insistía en pagar — mejor ir directo a donde de verdad se paga.
class _ProgramRow extends StatelessWidget {
  final GraphqlProgram program;

  /// Sin producto en la tienda no se sabe el precio: se invita a verlo en LSO.
  final bool enTienda;

  const _ProgramRow({required this.program, required this.enTienda});

  Future<void> _abrirEnLso(BuildContext context) async {
    final enlace = program.url;
    final messenger = ScaffoldMessenger.of(context);

    bool abierto = false;
    if (enlace != null) {
      final uri = Uri.parse(enlace);
      abierto = await canLaunchUrl(uri) &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!abierto) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No pudimos abrir la página del programa. Está en lso.school.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _abrirEnLso(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1B3156).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF306C9E).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMiniatura(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: GoogleFonts.barlow(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    enTienda ? (program.precioConMoneda ?? 'Cotización') : 'Ver en LSO',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.legacyActive,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, color: Color(0xFF9FB2C2), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniatura() {
    const double lado = 52;
    final url = program.imageUrl;

    Widget marcador() => Container(
      height: lado,
      width: lado,
      decoration: BoxDecoration(
        color: const Color(0xFF183D6B),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.school_outlined, size: 22, color: Colors.white.withValues(alpha: 0.25)),
    );

    if (url == null || url.isEmpty) return marcador();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: lado,
        width: lado,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => marcador(),
      ),
    );
  }
}
