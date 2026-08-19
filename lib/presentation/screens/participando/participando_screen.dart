import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../data/config/image_helper.dart';
import '../../../domain/models/registration_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/events_provider.dart';

/// Participando: los eventos en los que el usuario **está inscrito de verdad**.
///
/// Hasta el 2026-08-18 esta pantalla leía `assets/data/events_data.json` con
/// `rootBundle`: eventos de ejemplo compilados dentro de la app. Nunca consultó
/// el backend, así que jamás pudo mostrar una inscripción real —el cliente lo
/// reportó al no encontrar aquí su masterclass—. Ahora lee las mismas
/// inscripciones que "Mi credencial", de `GET /api/me/registrations`.
class ParticipandoScreen extends StatefulWidget {
  const ParticipandoScreen({super.key});

  @override
  State<ParticipandoScreen> createState() => _ParticipandoScreenState();
}

class _ParticipandoScreenState extends State<ParticipandoScreen> {
  String _busqueda = '';

  /// 'Todos', 'Presencial' o 'Virtual'. La modalidad viene de `eventIsVirtual`,
  /// que existe desde 20260818_modalidad_y_enlace_evento.sql. Antes el filtro
  /// comparaba contra un campo del JSON de ejemplo.
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    // Después del primer frame: leer el provider en initState directamente
    // rompe si todavía no está montado el árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated || auth.token == null) return;
    await context.read<EventsProvider>().loadMyRegistrations(auth.token!);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<EventsProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.legacyBlue1,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'PARTICIPANDO',
                textAlign: TextAlign.center,
                style: GoogleFonts.barlow(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(child: _buildCuerpo(auth, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildCuerpo(AuthProvider auth, EventsProvider provider) {
    if (!auth.isAuthenticated) {
      return _buildMensaje(
        icono: Icons.lock_outline,
        titulo: 'Inicia sesión',
        detalle: 'Aquí aparecen los eventos en los que te has inscrito.',
      );
    }

    if (provider.loadingRegistrations && provider.myRegistrations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.registrationsError != null && provider.myRegistrations.isEmpty) {
      return _buildMensaje(
        icono: Icons.cloud_off,
        titulo: 'No se pudieron cargar tus inscripciones',
        detalle: provider.registrationsError!,
        accion: 'Reintentar',
      );
    }

    if (provider.myRegistrations.isEmpty) {
      return _buildMensaje(
        icono: Icons.event_busy,
        titulo: 'Todavía no te has inscrito a ningún evento',
        detalle: 'Cuando te inscribas, tus eventos aparecerán aquí.',
      );
    }

    final filtradas = provider.myRegistrations.where((reg) {
      final coincideBusqueda = reg.eventTitle
          .toLowerCase()
          .contains(_busqueda.toLowerCase());
      final coincideFiltro = _filtro == 'Todos' ||
          (_filtro == 'Virtual' && reg.eventIsVirtual) ||
          (_filtro == 'Presencial' && !reg.eventIsVirtual);
      return coincideBusqueda && coincideFiltro;
    }).toList();

    final proximos = filtradas.where((r) => !r.eventoTerminado).toList();
    final pasados = filtradas.where((r) => r.eventoTerminado).toList();

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            onChanged: (valor) => setState(() => _busqueda = valor),
            decoration: InputDecoration(
              hintText: 'Buscar entre mis eventos...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos'),
                const SizedBox(width: 8),
                _buildFilterChip('Presencial'),
                const SizedBox(width: 8),
                _buildFilterChip('Virtual'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (proximos.isNotEmpty) ...[
            _buildTituloSeccion('Próximos eventos', AppTheme.legacyBlue1),
            const SizedBox(height: 10),
            ...proximos.map((reg) => _buildTarjeta(reg)),
            const SizedBox(height: 20),
          ],
          if (pasados.isNotEmpty) ...[
            _buildTituloSeccion('Eventos pasados', Colors.grey[700]!),
            const SizedBox(height: 10),
            ...pasados.map((reg) => _buildTarjeta(reg, pasado: true)),
          ],
          if (proximos.isEmpty && pasados.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'Ninguna de tus inscripciones coincide con este filtro',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTituloSeccion(String texto, Color color) => Text(
        texto,
        style: GoogleFonts.barlow(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      );

  Widget _buildMensaje({
    required IconData icono,
    required String titulo,
    required String detalle,
    String? accion,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 44, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.legacyBlue1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: GoogleFonts.mulish(color: Colors.grey[700], fontSize: 14),
            ),
            if (accion != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _cargar, child: Text(accion)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String etiqueta) {
    final seleccionado = _filtro == etiqueta;
    return GestureDetector(
      onTap: () => setState(() => _filtro = etiqueta),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppTheme.legacyBlue3 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppTheme.legacyBlue3 : Colors.grey,
          ),
        ),
        child: Text(
          etiqueta,
          style: GoogleFonts.mulish(
            color: seleccionado ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTarjeta(RegistrationModel reg, {bool pasado = false}) {
    final fecha = reg.eventStartDate != null
        ? DateFormat("d 'de' MMMM, y", 'es').format(reg.eventStartDate!)
        : '';
    final lugar = reg.eventIsVirtual
        ? 'Virtual en vivo'
        : (reg.eventLocation ?? 'Por confirmar');

    return Card(
      elevation: pasado ? 1 : 2,
      color: pasado ? Colors.grey[100] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  ImageHelper.getProxiedImageUrl(reg.eventImageUrl ?? ''),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: pasado ? Colors.grey : null,
                  colorBlendMode: pasado ? BlendMode.saturation : null,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140,
                    color: Colors.grey[300],
                    child: const Icon(Icons.event, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _buildEtiqueta(
                  reg.eventIsVirtual ? 'Virtual' : 'Presencial',
                  Colors.white.withValues(alpha: 0.9),
                  Colors.black,
                ),
              ),
              if (reg.estaPendienteDePago)
                Positioned(
                  top: 10,
                  left: 10,
                  child: _buildEtiqueta(
                    'Pendiente de pago',
                    AppTheme.legacyOrange,
                    Colors.white,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reg.eventTitle,
                  style: GoogleFonts.barlow(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: pasado ? Colors.grey[600] : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: pasado ? Colors.grey : AppTheme.legacyBlue3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fecha,
                      style: GoogleFonts.mulish(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      reg.eventIsVirtual
                          ? Icons.videocam_outlined
                          : Icons.location_on,
                      size: 14,
                      color: pasado ? Colors.grey : AppTheme.legacyBlue3,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lugar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.mulish(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                // Un evento ya terminado no lleva a ningún acceso, y una
                // inscripción sin pagar todavía no tiene ni QR ni enlace.
                if (!pasado && !reg.estaPendienteDePago) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/mi-credencial'),
                      icon: Icon(
                        reg.eventIsVirtual
                            ? Icons.videocam_rounded
                            : Icons.qr_code_2_rounded,
                        size: 18,
                      ),
                      label: Text(
                        reg.eventIsVirtual
                            ? 'Ver enlace de acceso'
                            : 'Ver mi credencial',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.legacyOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtiqueta(String texto, Color fondo, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: color,
          ),
        ),
      );
}
