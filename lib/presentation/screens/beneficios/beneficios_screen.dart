import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/services/beneficios_service.dart';
import '../../../data/services/solo_plus.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/boton_volver.dart';

/// Sección Beneficios, desde la fila del mismo nombre del Inicio (2026-10-13).
/// Solo para usuarios Legacy+: el backend responde 403 al resto y aquí se
/// explica. Dos sliders, Beneficios y Alianzas, con su propio contenido en el
/// panel (no es el de la pantalla Legacy+).
class BeneficiosScreen extends StatefulWidget {
  /// Se inyecta en las pruebas; por defecto, el real.
  final BeneficiosService? servicio;

  const BeneficiosScreen({super.key, this.servicio});

  @override
  State<BeneficiosScreen> createState() => _BeneficiosScreenState();
}

class _BeneficiosScreenState extends State<BeneficiosScreen> {
  late Future<List<Beneficio>> _tarjetas;

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _tarjetas = (widget.servicio ?? BeneficiosService()).beneficios(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.legacyBlue1,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
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
            ),
            const SizedBox(height: 24),
            FutureBuilder<List<Beneficio>>(
              future: _tarjetas,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  final soloPlus = snapshot.error is SoloPlusException;
                  return _aviso(
                    soloPlus
                        ? snapshot.error.toString()
                        : 'No pudimos cargar los beneficios. Revisa tu conexión e inténtalo de nuevo.',
                    soloPlus: soloPlus,
                  );
                }
                final todas = snapshot.data!;
                final beneficios = todas.where((b) => b.tipo != 'alianza').toList();
                final alianzas = todas.where((b) => b.tipo == 'alianza').toList();
                if (beneficios.isEmpty && alianzas.isEmpty) {
                  return _aviso('Pronto publicaremos los beneficios.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (beneficios.isNotEmpty)
                      _Slider(key: const Key('slider-beneficios'), titulo: 'BENEFICIOS', tarjetas: beneficios),
                    if (beneficios.isNotEmpty && alianzas.isNotEmpty) const SizedBox(height: 32),
                    if (alianzas.isNotEmpty)
                      _Slider(key: const Key('slider-alianzas'), titulo: 'ALIANZAS', tarjetas: alianzas),
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
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
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

/// Un slider horizontal de tarjetas con indicador de página.
class _Slider extends StatefulWidget {
  final String titulo;
  final List<Beneficio> tarjetas;

  const _Slider({super.key, required this.titulo, required this.tarjetas});

  @override
  State<_Slider> createState() => _SliderState();
}

class _SliderState extends State<_Slider> {
  final _controlador = PageController(viewportFraction: 0.86);
  int _pagina = 0;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.titulo,
            style: GoogleFonts.barlow(
              color: AppTheme.legacyActive,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _controlador,
            itemCount: widget.tarjetas.length,
            onPageChanged: (p) => setState(() => _pagina = p),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _Tarjeta(beneficio: widget.tarjetas[i]),
            ),
          ),
        ),
        if (widget.tarjetas.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.tarjetas.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _pagina ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _pagina ? AppTheme.legacyActive : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  final Beneficio beneficio;

  const _Tarjeta({required this.beneficio});

  Future<void> _abrir(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(beneficio.enlaceUrl);
    final abierto = uri != null &&
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto) {
      messenger.showSnackBar(const SnackBar(content: Text('No pudimos abrir el enlace.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = beneficio;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.legacySurface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.legacyBlue3.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: b.imagenUrl.isEmpty
                ? Container(
                    color: AppTheme.legacyBlue2,
                    child: const Icon(Icons.card_giftcard_outlined, color: AppTheme.legacyActive, size: 48),
                  )
                : CachedNetworkImage(
                    imageUrl: b.imagenUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.legacyBlue2),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.legacyBlue2,
                      child: const Icon(Icons.card_giftcard_outlined, color: AppTheme.legacyActive, size: 48),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.barlow(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      b.descripcion,
                      overflow: TextOverflow.fade,
                      style: GoogleFonts.questrial(
                        color: const Color(0xFF9FB2C2),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (b.enlaceUrl.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _abrir(context),
                        icon: const Icon(Icons.open_in_new, size: 16, color: AppTheme.legacyActive),
                        label: Text(
                          'Ver más',
                          style: GoogleFonts.barlow(
                            color: AppTheme.legacyActive,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
