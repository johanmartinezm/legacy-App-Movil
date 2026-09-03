import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/models/program_model.dart';
import '../../../data/services/graphql_service.dart';
import '../../widgets/boton_volver.dart';

/// Programas de LSO agrupados en 3 secciones fijas, en vez de la lista plana
/// de hasta 32 cursos que había hasta el 2026-08-22.
///
/// Estructura propuesta por el cliente (revisión de Diana Uribe, LSO,
/// 22-08-2026): certificación con doble sello EUDE, actualización, e
/// in-company/in-family. De los 8 títulos que trajo la propuesta original,
/// 4 no existen en la tienda con ese nombre — comprobado contra el GraphQL de
/// `lso.school` el mismo día. Dos tenían un programa real bajo un título
/// distinto (se usa el real, con su enlace); dos no tienen ningún programa
/// parecido y se dejaron fuera en vez de mostrar una tarjeta sin destino.
const List<String> _titulosCertificacionEude = [
  'Programa de Formación para Familias Empresarias y Propietarios',
  'Certificación Internacional en Gobierno Corporativo',
  'Programa de Formación de Consultores en Empresa Familiar',
];

// "Curso Introducción al Manejo de Riesgo Cambiario en el Sector Real" y
// "Gestión de conflictos en la empresa familiar" y "Board branding..." no
// tienen programa real: solo estos tres existen en la tienda.
const List<String> _titulosActualizacion = [
  'Juntas, Consejos y Directorios que Crean Valor',
  'Gestión del Riesgo Cambiario: Conceptos y Herramientas',
  'Gestión Patrimonial para Empresarios',
];

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  List<GraphqlProgram> _certificacionEude = [];
  List<GraphqlProgram> _actualizacion = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    try {
      // 32 programas hoy en la tienda; 50 deja margen sin tener que paginar.
      final todos = await GraphqlService().getPrograms(first: 50);

      if (mounted) {
        setState(() {
          _certificacionEude = _porTitulos(todos, _titulosCertificacionEude);
          _actualizacion = _porTitulos(todos, _titulosActualizacion);
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

  /// Busca cada título en orden y solo incluye los que existen de verdad en
  /// la tienda — si LSO renombra o retira un programa, la sección lo pierde
  /// en vez de mostrar una tarjeta sin enlace.
  List<GraphqlProgram> _porTitulos(List<GraphqlProgram> todos, List<String> titulos) {
    return titulos
        .map((titulo) {
          for (final p in todos) {
            if (p.name.trim().toLowerCase() == titulo.trim().toLowerCase()) {
              return p;
            }
          }
          return null;
        })
        .whereType<GraphqlProgram>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF13304A),
              Color(0xFF0E2C3B),
              Color(0xFF050B15),
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
                            child: CircularProgressIndicator(color: Color(0xFFD9A74A)),
                          ),
                        )
                      else ...[
                        _buildSeccion(
                          titulo: 'PROGRAMAS CON CERTIFICACIÓN EUDE',
                          descripcion: 'Doble sello internacional con EUDE Business School.',
                          programas: _certificacionEude,
                        ),
                        const SizedBox(height: 28),
                        _buildSeccion(
                          titulo: 'PROGRAMAS DE ACTUALIZACIÓN',
                          descripcion: null,
                          programas: _actualizacion,
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
    required List<GraphqlProgram> programas,
  }) {
    if (programas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.barlow(
            color: const Color(0xFFD9A74A),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        if (descripcion != null) ...[
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: GoogleFonts.questrial(color: const Color(0xFF90A4BA), fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        ...programas.map((p) => _ProgramRow(program: p)),
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
          color: const Color(0xFF0B1A2E).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.design_services_outlined, color: Color(0xFFD9A74A), size: 26),
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
                    style: GoogleFonts.questrial(color: const Color(0xFF90A4BA), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF90A4BA), size: 20),
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
          color: const Color(0xFF0B1A2E).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: Color(0xFFD9A74A), size: 22),
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
                      color: const Color(0xFF90A4BA),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF90A4BA), size: 20),
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
                  'LSO · Legacy School of Ownership',
                  style: GoogleFonts.barlow(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'La escuela del propietario en LATAM',
                  style: GoogleFonts.questrial(
                    fontSize: 12,
                    color: const Color(0xFF90A4BA),
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
        color: const Color(0xFF0B1A2E).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formación que los MBA no dan',
            style: GoogleFonts.barlow(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Programas para gobernar la empresa y proteger el patrimonio. '
            'Doble certificación LSO + EUDE ⭐, con contenido académico de '
            'Harvard Business Impact. Alumni LSO acceden a Legacy+ con precio especial.',
            style: GoogleFonts.questrial(
              fontSize: 13,
              color: const Color(0xFF90A4BA),
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

  const _ProgramRow({required this.program});

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
          color: const Color(0xFF0B1A2E).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
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
                    program.precioConMoneda ?? 'Cotización',
                    style: GoogleFonts.barlow(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD9A74A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, color: Color(0xFF90A4BA), size: 18),
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
        color: const Color(0xFF13304A),
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
