import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/program_model.dart';
import '../../../data/services/graphql_service.dart';

// Modelo de datos para programa LSO (estático, ajustado al diseño visual)
class _LsoProgram {
  final String title;
  final String details;
  final String price;
  final String? priceNote;
  final bool isQuote; // true = muestra "Cotización" en dorado en vez de precio
  // La imagen del producto en la tienda de LSO. Puede faltar: no todos los
  // programas la tienen cargada, y la tarjeta se dibuja igual sin ella.
  final String? imageUrl;

  // El id y el enlace del producto en la tienda, tal como llegan del GraphQL.
  //
  // Se conservan porque la pantalla de detalle recibe un GraphqlProgram
  // **reconstruido** a partir de esta tarjeta, y hasta el 2026-08-20 esa copia
  // nacía sin enlace y con un id inventado a partir del título: «Inscribirme en
  // LSO» no abría nada y avisaba de que no pudo. Lo que no se guarde aquí, se
  // pierde por el camino.
  final String? id;
  final String? url;

  const _LsoProgram({
    required this.title,
    required this.details,
    required this.price,
    this.priceNote,
    this.isQuote = false,
    this.imageUrl,
    this.id,
    this.url,
  });
}

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  List<_LsoProgram> _programs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    try {
      final graphqlPrograms = await GraphqlService().getPrograms(first: 20);
      
      if (mounted) {
        setState(() {
          _programs = graphqlPrograms.map((p) {
            String cleanDetails = p.shortDescription != null && p.shortDescription!.isNotEmpty 
                ? p.shortDescription!.replaceAll(RegExp(r'<[^>]*>'), '').trim() 
                : '${p.modality} · ${p.type}';
                
            // Limitar details para que no sea muy largo si viene con mucho HTML
            if (cleanDetails.length > 60) {
              cleanDetails = '${cleanDetails.substring(0, 57)}...';
            }

            return _LsoProgram(
              title: p.name,
              details: cleanDetails,
              price: p.precioConMoneda ?? 'Cotización',
              priceNote: p.type,
              isQuote: p.precioConMoneda == null,
              imageUrl: p.imageUrl,
              id: p.id,
              url: p.url,
            );
          }).toList();
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
                      const SizedBox(height: 28),

                      // Etiqueta de sección
                      Text(
                        'PROGRAMAS ABIERTOS 2026',
                        style: GoogleFonts.barlow(
                          color: const Color(0xFFD9A74A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lista de programas
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: Color(0xFFD9A74A)),
                          ),
                        )
                      else if (_programs.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No hay programas disponibles en este momento.',
                              style: GoogleFonts.barlow(color: Colors.white70),
                            ),
                          ),
                        )
                      else
                        ..._programs.map((p) => _ProgramCard(program: p)),
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

  // ── Cabecera con botón de retorno ──────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botón de retorno
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1A2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ),
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

// ── Tarjeta de programa ────────────────────────────────────────────────────────
class _ProgramCard extends StatelessWidget {
  final _LsoProgram program;

  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Map static program details to GraphqlProgram fields to populate the detail screen
        String shortDesc = '🎓 LSO · Doble certificación LSO + EUDE';
        String desc = '';
        String format = 'Virtual en vivo + grabaciones';
        String cert = 'LSO + EUDE 5★ QS';
        String cuotas = 'Hasta 3 cuotas';

        if (program.title.contains('Propietarios')) {
          desc = 'USD 2.100 · o por módulo desde USD 630. Contenido académico de Harvard Business Impact y profesores de LATAM, Europa y EE.UU. Puede cursarse completo o por módulo.';
        } else if (program.title.contains('Gobierno')) {
          desc = 'USD 2.500. Formación avanzada para miembros de junta directiva, consejeros y accionistas de empresas en LATAM. Doble titulación internacional.';
        } else if (program.title.contains('Consultores')) {
          shortDesc = '🎓 LSO · Alianza ICOEF · doble certificación';
          desc = 'USD 1.100. Especialización para consultores y asesores de familias empresarias. Metodología práctica y herramientas de intervención certificadas.';
          cert = 'LSO + ICOEF';
        } else if (program.title.contains('Company')) {
          shortDesc = '🎓 LSO · Programas a medida';
          desc = 'Cotización. Diseñamos el programa formativo o protocolo familiar que su organización y familia empresaria requieren, con flexibilidad total de agenda.';
          format = 'Presencial / Híbrido a medida';
          cert = 'LSO Certificación Corporativa';
          cuotas = 'A convenir';
        }

        // El id y el enlace salen del producto real, no del título: son lo
        // único que no se puede reconstruir aquí, y el enlace es lo que abre
        // «Inscribirme en LSO».
        final graphqlProgram = GraphqlProgram(
          id: program.id ?? program.title.toLowerCase().replaceAll(' ', '-'),
          name: program.title,
          url: program.url,
          description: desc,
          shortDescription: shortDesc,
          price: program.price,
          modality: format,
          duration: cert,
          type: cuotas,
        );

        context.push('/programa-detalle', extra: graphqlProgram);
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A2E).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        // clipBehavior recorta la imagen a las esquinas del contenedor; sin él
        // sobresale por las cuatro puntas.
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgramImage(program.imageUrl),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Título
            Text(
              program.title,
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),

            // Detalles (horas · módulos · fecha)
            Text(
              program.details,
              style: GoogleFonts.questrial(
                fontSize: 12,
                color: const Color(0xFF90A4BA),
              ),
            ),
            const SizedBox(height: 10),

            // Precio o Cotización
            Text(
              program.price,
              style: GoogleFonts.barlow(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD9A74A),
              ),
            ),

            // Nota extra (debajo del precio)
            if (program.priceNote != null) ...[
              const SizedBox(height: 4),
              Text(
                program.priceNote!,
                style: GoogleFonts.questrial(
                  fontSize: 12,
                  color: const Color(0xFF90A4BA),
                ),
              ),
            ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cabecera de la tarjeta de programa. La imagen llega del producto en la
  /// tienda de LSO; cuando falta se dibuja el mismo bloque con el emblema, para
  /// que las tarjetas mantengan la altura y el listado no quede irregular.
  Widget _buildProgramImage(String? url) {
    const double alto = 132;

    Widget marcador() => Container(
      height: alto,
      width: double.infinity,
      color: const Color(0xFF13304A),
      alignment: Alignment.center,
      child: Icon(
        Icons.school_outlined,
        size: 40,
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );

    if (url == null || url.isEmpty) return marcador();

    return Image.network(
      url,
      height: alto,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => marcador(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: alto,
          width: double.infinity,
          color: const Color(0xFF13304A),
          alignment: Alignment.center,
          child: const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}
