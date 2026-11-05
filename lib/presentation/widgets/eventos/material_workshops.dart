import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../config/theme/app_theme.dart';
import '../../../data/config/api_constants.dart';
import '../../../data/config/image_helper.dart';
import '../../../domain/models/event_model.dart';
import '../../../domain/models/workshop_model.dart';
import '../boton_volver.dart';

const _cian = Color(0xFF00F2FE);
const _textoSecundario = Color(0xFF9FB2C2);

/// «Material de los workshops» en el detalle de un evento (parte A del plan de
/// workshops). Una tarjeta por cada workshop **que ya terminó** y tiene
/// material; en un evento de varios días ya salen los de los días pasados.
/// Sin ninguno, la sección no aparece.
class MaterialWorkshops extends StatelessWidget {
  final EventModel event;

  /// Para fijar «ahora» en los tests.
  final DateTime? ahora;

  const MaterialWorkshops({super.key, required this.event, this.ahora});

  /// Los workshops que se muestran: terminados, con material, por hora.
  static List<WorkshopModel> conMaterial(EventModel event, {DateTime? ahora}) {
    final ref = ahora ?? DateTime.now();
    return event.workshops
        .where((w) => w.endDateTime.isBefore(ref) && !w.material.vacio)
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  @override
  Widget build(BuildContext context) {
    final lista = conMaterial(event, ahora: ahora);
    if (lista.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('material-workshops'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Material de los workshops',
          style: GoogleFonts.barlow(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...lista.map((w) => _TarjetaMaterial(workshop: w)),
      ],
    );
  }
}

class _TarjetaMaterial extends StatelessWidget {
  final WorkshopModel workshop;

  const _TarjetaMaterial({required this.workshop});

  MaterialWorkshop get m => workshop.material;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('material-${workshop.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.legacySurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.legacyBlue2.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workshop.name,
            style: GoogleFonts.barlow(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat(
              "d 'de' MMMM · HH:mm",
              'es',
            ).format(workshop.startDateTime),
            style: GoogleFonts.barlow(fontSize: 13, color: _textoSecundario),
          ),
          if (m.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Imagen(url: m.imageUrl),
          ],
          if (m.fileName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Accion(
              key: Key('descargar-${workshop.id}'),
              icono: Icons.download_outlined,
              texto: 'Descargar',
              detalle: _detalleArchivo(),
              alTocar: () => _abrirFuera(context, urlDeDescarga(m.fileName)),
            ),
          ],
          if (m.videoUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Accion(
              key: Key('video-${workshop.id}'),
              icono: m.esYoutube
                  ? Icons.play_circle_outline
                  : Icons.open_in_new,
              texto: m.esYoutube ? 'Ver video' : 'Ver video en Vimeo',
              detalle: m.esYoutube ? null : 'Se abre fuera de la app',
              alTocar: () => m.esYoutube
                  ? Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VideoDeWorkshopScreen(
                          titulo: workshop.name,
                          url: m.videoUrl,
                        ),
                      ),
                    )
                  : _abrirFuera(context, m.videoUrl),
            ),
          ],
        ],
      ),
    );
  }

  String _detalleArchivo() {
    final nombre = m.fileOriginalName.isNotEmpty
        ? m.fileOriginalName
        : m.fileName;
    if (m.fileSize <= 0) return nombre;
    final tam = m.fileSize >= 1024 * 1024
        ? '${(m.fileSize / 1024 / 1024).toStringAsFixed(1)} MB'
        : '${(m.fileSize / 1024).ceil()} KB';
    return '$nombre · $tam';
  }
}

/// Dirección de descarga del archivo del material.
String urlDeDescarga(String fileName) =>
    '${ApiConstants.baseUrl}/api/documents/${Uri.encodeComponent(fileName)}';

Future<void> _abrirFuera(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final ok =
      uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pudimos abrirlo. Inténtalo de nuevo.')),
    );
  }
}

class _Accion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String? detalle;
  final VoidCallback alTocar;

  const _Accion({
    super.key,
    required this.icono,
    required this.texto,
    required this.alTocar,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cian.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icono, color: _cian, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: GoogleFonts.barlow(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _cian,
                    ),
                  ),
                  if (detalle != null)
                    Text(
                      detalle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlow(
                        fontSize: 12,
                        color: _textoSecundario,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Imagen del material: se amplía al tocarla (decidido el 2026-10-28).
class _Imagen extends StatelessWidget {
  final String url;

  const _Imagen({required this.url});

  @override
  Widget build(BuildContext context) {
    final src = ImageHelper.getProxiedImageUrl(url);
    return GestureDetector(
      key: const Key('material-imagen'),
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(child: Image.network(src)),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 12 / 7,
          child: Image.network(
            src,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppTheme.legacyBlue1,
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 36,
                  color: AppTheme.legacyActive,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El video de YouTube del material, dentro de la app, con el mismo reproductor
/// que Legacy Knowledge.
class VideoDeWorkshopScreen extends StatefulWidget {
  final String titulo;
  final String url;

  const VideoDeWorkshopScreen({
    super.key,
    required this.titulo,
    required this.url,
  });

  @override
  State<VideoDeWorkshopScreen> createState() => _VideoDeWorkshopScreenState();
}

class _VideoDeWorkshopScreenState extends State<VideoDeWorkshopScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(widget.url) ?? '',
      flags: const YoutubePlayerFlags(autoPlay: true),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
      ),
      builder: (context, player) => Scaffold(
        backgroundColor: AppTheme.legacyBlue1,
        appBar: AppBar(
          backgroundColor: AppTheme.legacyBlue1,
          leading: const BotonVolver(),
          title: Text(
            widget.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlow(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(children: [player]),
      ),
    );
  }
}
