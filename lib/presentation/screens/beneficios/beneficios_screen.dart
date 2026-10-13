import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/services/legacy_plus_service.dart';
import '../../../data/services/secciones_inicio_service.dart';
import '../../../data/services/solo_plus.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/boton_volver.dart';
import '../../widgets/punto_check.dart';

/// Sección Beneficios, desde la fila del mismo nombre del Inicio (2026-10-13).
/// Solo para usuarios Legacy+: el backend responde 403 al resto y aquí se
/// explica. El contenido son los puntos del grupo «beneficios» de «Puntos de
/// Legacy+» del panel, con su texto completo.
class BeneficiosScreen extends StatefulWidget {
  /// Se inyectan en las pruebas; por defecto, los reales.
  final LegacyPlusService? puntosService;
  final SeccionesInicioService? textosService;

  const BeneficiosScreen({super.key, this.puntosService, this.textosService});

  @override
  State<BeneficiosScreen> createState() => _BeneficiosScreenState();
}

class _BeneficiosScreenState extends State<BeneficiosScreen> {
  late Future<List<PuntoLegacyPlus>> _beneficios;
  String _subtitulo = 'BENEFICIOS';

  @override
  void initState() {
    super.initState();
    _beneficios = _cargar();
    _cargarSubtitulo();
  }

  Future<List<PuntoLegacyPlus>> _cargar() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    return (widget.puntosService ?? LegacyPlusService()).beneficios(token);
  }

  Future<void> _cargarSubtitulo() async {
    final textos = await (widget.textosService ?? SeccionesInicioService()).secciones();
    final titulo = textos['lp-beneficios']?.titulo;
    if (mounted && titulo != null) setState(() => _subtitulo = titulo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                const BotonVolver(),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Beneficios',
                    style: GoogleFonts.barlow(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<PuntoLegacyPlus>>(
              future: _beneficios,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _aviso(
                    snapshot.error is SoloPlusException
                        ? snapshot.error.toString()
                        : 'No pudimos cargar los beneficios. Revisa tu conexión e inténtalo de nuevo.',
                    soloPlus: snapshot.error is SoloPlusException,
                  );
                }
                final beneficios = snapshot.data!;
                if (beneficios.isEmpty) {
                  return _aviso('Pronto publicaremos los beneficios.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subtitulo,
                      style: GoogleFonts.barlow(
                        color: AppTheme.legacyActive,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final (i, b) in beneficios.indexed) ...[
                      if (i > 0) const SizedBox(height: 16),
                      PuntoCheck(titulo: b.titulo, texto: b.texto),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _aviso(String mensaje, {bool soloPlus = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(
            soloPlus ? Icons.lock_outline : Icons.info_outline,
            color: AppTheme.legacyActive,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            key: const Key('beneficios-aviso'),
            textAlign: TextAlign.center,
            style: GoogleFonts.questrial(color: const Color(0xFF9FB2C2), fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
