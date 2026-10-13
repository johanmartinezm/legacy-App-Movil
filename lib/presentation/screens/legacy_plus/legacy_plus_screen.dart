import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/legacy_plus_service.dart';
import '../../../data/services/secciones_inicio_service.dart';
import '../../widgets/boton_volver.dart';
import 'package:legacy_app/config/theme/app_theme.dart';

/// Pantalla Legacy+ (pestaña inferior). Desde el 2026-10-13 su contenido se
/// administra en el panel: los textos fijos en «Textos de Legacy+» (filas de
/// secciones_inicio con pantalla «legacy-plus») y los puntos con check en
/// «Puntos de Legacy+». Lo que no llegue —sin backend, o vacío— se ve como
/// estaba escrito aquí.
class LegacyPlusScreen extends StatefulWidget {
  /// Se inyectan en las pruebas; por defecto, los reales.
  final SeccionesInicioService? textosService;
  final LegacyPlusService? puntosService;

  const LegacyPlusScreen({super.key, this.textosService, this.puntosService});

  @override
  State<LegacyPlusScreen> createState() => _LegacyPlusScreenState();
}

class _LegacyPlusScreenState extends State<LegacyPlusScreen> {
  Map<String, SeccionInicio> _textos = const {};
  List<PuntoLegacyPlus> _puntos = PuntoLegacyPlus.porDefecto;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resultados = await Future.wait([
      (widget.textosService ?? SeccionesInicioService()).secciones(),
      (widget.puntosService ?? LegacyPlusService()).puntos(),
    ]);
    if (!mounted) return;
    final textos = resultados[0] as Map<String, SeccionInicio>;
    final puntos = resultados[1] as List<PuntoLegacyPlus>?;
    setState(() {
      _textos = textos;
      if (puntos != null) _puntos = puntos;
    });
  }

  String _titulo(String slug, String porDefecto) =>
      _textos[slug]?.titulo ?? porDefecto;

  String _texto(String slug, String porDefecto) =>
      _textos[slug]?.texto ?? porDefecto;

  /// Los puntos de un grupo; si el panel no tiene ninguno activo, los de
  /// siempre, para que la pantalla no quede con un título sin nada debajo.
  List<PuntoLegacyPlus> _grupo(String grupo) {
    final propios = _puntos.where((p) => p.grupo == grupo).toList();
    if (propios.isNotEmpty) return propios;
    return PuntoLegacyPlus.porDefecto.where((p) => p.grupo == grupo).toList();
  }

  /// Los puntos de un grupo con su separación.
  List<Widget> _checks(String grupo) => [
        for (final (i, p) in _grupo(grupo).indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          _buildCheckItem(p.titulo, p.texto),
        ],
      ];

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
              Color(0xFF1B3156),
              Color(0xFF162540),
              Color(0xFF162540),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header / AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const BotonVolver(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Legacy+',
                            style: GoogleFonts.barlow(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'El acceso completo al ecosistema',
                            style: GoogleFonts.questrial(
                              fontSize: 13,
                              color: const Color(0xFF9FB2C2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Top Info Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1B3156).withValues(alpha: 0.95),
                              const Color(0xFF081220).withValues(alpha: 0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.legacyActive.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Gold L Logo Square
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.legacyBlue5,
                                    AppTheme.legacyActive,
                                    AppTheme.legacyBlue3,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'L',
                                  style: GoogleFonts.barlow(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF162540),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Título y texto del cliente, 2026-10-13. Antes:
                            // «¿Qué es Legacy+?» y, ese mismo día, «Cómo accedo:
                            // debes ser cliente de alguna unidad…».
                            Text(
                              _titulo('lp-banner', 'LEGACY+'),
                              style: GoogleFonts.barlowCondensed(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _texto(
                                'lp-banner',
                                'Servicios y beneficios plus para los clientes de Legacy Network o Alumni LSO',
                              ),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.questrial(
                                color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Texto del cliente bajo el banner, 2026-10-13.
                      Text(
                        _texto(
                          'lp-como-accedo',
                          'Cómo accedo: debes ser cliente de alguna unidad de negocio o ser alumni de LSO. Tiene acceso a:',
                        ),
                        key: const Key('legacy-plus-como-accedo'),
                        style: GoogleFonts.questrial(
                          color: const Color(0xFFE8EEF5).withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Puntos «Tiene acceso a» y «Beneficios»: los administra
                      // el panel («Puntos de Legacy+»).
                      ..._checks('incluye'),
                      const SizedBox(height: 28),

                      Text(
                        _titulo('lp-beneficios', 'BENEFICIOS'),
                        style: GoogleFonts.barlow(
                          color: AppTheme.legacyActive,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._checks('beneficios'),
                      // Hasta aquí llega la pantalla desde el 2026-10-13: el
                      // cliente retiró «YA TIENE LEGACY+ SI ES…», el precio
                      // (COP 1.790.000 / año) y la lista anterior de lo que
                      // incluía.
                      const SizedBox(height: 20),
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

  Widget _buildCheckItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green Check Icon
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF0F2F20),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check,
              color: Color(0xFF2ECC71),
              size: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Title and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.barlow(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.questrial(
                  fontSize: 13,
                  color: const Color(0xFF9FB2C2),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
