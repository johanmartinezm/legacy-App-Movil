import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/services/paginas_service.dart';
import '../../../domain/models/pagina_informativa_model.dart';
import '../../widgets/boton_volver.dart';

/// Pinta una página cuyo contenido vive en el panel administrativo.
///
/// La pantalla no sabe nada del tema del que habla: recibe un `slug`, lo pide
/// al backend y muestra lo que venga. Añadir otra página informativa es
/// registrar una ruta más apuntando aquí, sin escribir otra pantalla.
///
/// `tituloProvisional` es lo que se muestra en la barra mientras carga y si la
/// carga falla: dejar la barra vacía haría parecer que la app se rompió.
class PaginaInformativaScreen extends StatefulWidget {
  final String slug;
  final String tituloProvisional;

  /// Se inyecta solo en las pruebas, igual que el cliente http de los
  /// servicios: en la app va siempre el de verdad.
  final PaginasService? servicio;

  const PaginaInformativaScreen({
    super.key,
    required this.slug,
    required this.tituloProvisional,
    this.servicio,
  });

  @override
  State<PaginaInformativaScreen> createState() => _PaginaInformativaScreenState();
}

class _PaginaInformativaScreenState extends State<PaginaInformativaScreen> {
  late final PaginasService _servicio;
  late Future<PaginaInformativa> _pagina;

  @override
  void initState() {
    super.initState();
    _servicio = widget.servicio ?? PaginasService();
    _pagina = _servicio.obtener(widget.slug);
  }

  void _reintentar() {
    setState(() {
      _pagina = _servicio.obtener(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tituloProvisional),
        leading: const BotonVolver(),
      ),
      body: SafeArea(
        child: FutureBuilder<PaginaInformativa>(
          future: _pagina,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _error(context, snapshot.error!);
            }
            return _contenido(context, snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _error(BuildContext context, Object error) {
    // PaginaNoDisponible ya trae un mensaje escrito para leerse; cualquier otra
    // excepción se resume, porque su texto es técnico.
    final mensaje = error is PaginaNoDisponible
        ? error.mensaje
        : 'No pudimos cargar el contenido. Revisa tu conexión e inténtalo de nuevo.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _reintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenido(BuildContext context, PaginaInformativa pagina) {
    final parrafos = pagina.parrafos;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pagina.imagenUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: pagina.imagenUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.black12,
              ),
              // Una imagen que no carga no puede tumbar la página: lo que
              // importa aquí es el texto.
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pagina.titulo,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (pagina.subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    pagina.subtitulo,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (parrafos.isEmpty)
                  const Text(
                    'Pronto publicaremos el contenido de esta sección.',
                    style: TextStyle(fontSize: 15, height: 1.6),
                  )
                else
                  ...parrafos.map(
                    (parrafo) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        parrafo,
                        style: const TextStyle(fontSize: 15, height: 1.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
