import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/services/legacy_plus_service.dart';
import '../../../data/services/secciones_inicio_service.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/boton_volver.dart';
import '../../widgets/punto_check.dart';
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
    // Que activar el Legacy+ en el panel se note al entrar aquí, sin cerrar
    // sesión: el perfil trae es_plus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) auth.fetchProfile();
    });
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

  /// Los tres accesos de un usuario Legacy+, con el título y el texto que el
  /// panel les pone en el Inicio (slugs `chats-sinergia`, `miembros` y
  /// `beneficios` de «Tarjetas del Inicio»).
  List<Widget> _accesosPlus(BuildContext context) {
    const accesos = [
      (
        'chats-sinergia',
        'Chats de sinergia',
        'Chats de sinergia entre pares: hay 4 chats para hablar de temas de Empresa, Patrimonio, Familia y otros entre miembros de otras familias empresarias.',
        Icons.forum_outlined,
        '/forums',
      ),
      (
        'miembros',
        'Legacy Board',
        'Red de gobierno corporativo que conecta a familias empresarias y empresas que necesitan crear o fortalecer sus órganos de gobierno (juntas directivas, consejos de familia, directorios, advisory boards y comités) con profesionales que quieren servir en ellos.',
        Icons.dashboard_outlined,
        '/legacy-board',
      ),
      (
        'beneficios',
        'Beneficios',
        'Son descuentos y servicios especiales de aliados o de Legacy Network.',
        Icons.card_giftcard_outlined,
        '/beneficios',
      ),
    ];
    return [
      Text(
        'TU ACCESO LEGACY+',
        key: const Key('legacy-plus-accesos'),
        style: GoogleFonts.barlow(
          color: AppTheme.legacyActive,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 16),
      for (final (i, (slug, titulo, texto, icono, ruta)) in accesos.indexed) ...[
        if (i > 0) const SizedBox(height: 10),
        _filaAcceso(
          context,
          titulo: _textos[slug]?.titulo ?? titulo,
          texto: _textos[slug]?.texto ?? texto,
          icono: icono,
          ruta: ruta,
        ),
      ],
    ];
  }

  /// Fila de acceso, con el mismo aspecto que las filas abiertas del Inicio.
  Widget _filaAcceso(
    BuildContext context, {
    required String titulo,
    required String texto,
    required IconData icono,
    required String ruta,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => context.push(ruta),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF54C6A8).withValues(alpha: 0.06),
                const Color(0xFF54C6A8).withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF54C6A8).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF54C6A8).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icono, color: const Color(0xFF54C6A8), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.barlowCondensed(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      texto,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.questrial(
                        color: const Color(0xFF9FB2C2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.legacyActive, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lo que ve un usuario Legacy+ cambia: ver _accesosPlus.
    final esPlus = Provider.of<AuthProvider>(context).esPlus;
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

                      // Usuario Legacy+: sus tres accesos, los mismos de la
                      // sección Legacy+ del Inicio. El resto: lo informativo
                      // («Cómo accedo…» y los puntos). Pedido del 2026-10-13.
                      if (esPlus)
                        ..._accesosPlus(context)
                      else ...[
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
                      ],
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

  Widget _buildCheckItem(String title, String description) =>
      PuntoCheck(titulo: title, texto: description);
}
