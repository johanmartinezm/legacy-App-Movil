import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../domain/models/registration_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/events_provider.dart';

/// Mi credencial: el QR de acceso de **todos** los eventos en los que el usuario
/// está inscrito.
///
/// Antes el único QR alcanzable era el del botón flotante de la agenda, que
/// mostraba siempre el del primer taller y no aparecía si la agenda estaba
/// vacía. Inscribirse a un evento no llena la agenda, así que una inscripción
/// perfectamente válida podía quedarse sin ninguna forma de enseñarse.
class MiCredencialScreen extends StatefulWidget {
  const MiCredencialScreen({super.key});

  @override
  State<MiCredencialScreen> createState() => _MiCredencialScreenState();
}

class _MiCredencialScreenState extends State<MiCredencialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<EventsProvider>().loadMyRegistrations(token);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final nombre = context.read<AuthProvider>().fullName;

    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mi credencial',
          style: GoogleFonts.barlow(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _buildCuerpo(provider, nombre),
      ),
    );
  }

  Widget _buildCuerpo(EventsProvider provider, String? nombre) {
    if (provider.loadingRegistrations && provider.myRegistrations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.registrationsError != null &&
        provider.myRegistrations.isEmpty) {
      return _buildMensaje(
        icono: Icons.wifi_off_rounded,
        titulo: 'No pudimos cargar tus credenciales',
        detalle: provider.registrationsError!,
      );
    }

    if (provider.myRegistrations.isEmpty) {
      return _buildMensaje(
        icono: Icons.confirmation_number_outlined,
        titulo: 'Todavía no tienes eventos',
        detalle:
            'Cuando reserves un cupo, aquí aparecerá tu código de acceso para presentarlo en la entrada.',
      );
    }

    // Los que ya pasaron van al final: lo que sirve para entrar hoy es lo de
    // arriba.
    final vigentes =
        provider.myRegistrations.where((r) => !r.eventoTerminado).toList();
    final pasados =
        provider.myRegistrations.where((r) => r.eventoTerminado).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (nombre != null && nombre.isNotEmpty) ...[
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Presenta el código en la entrada del evento',
            textAlign: TextAlign.center,
            style: GoogleFonts.questrial(
              fontSize: 13,
              color: const Color(0xFF90A4BA),
            ),
          ),
          const SizedBox(height: 20),
        ],
        ...vigentes.map(_buildTarjeta),
        if (pasados.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Eventos pasados',
            style: GoogleFonts.barlow(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF90A4BA),
            ),
          ),
          const SizedBox(height: 12),
          ...pasados.map(_buildTarjeta),
        ],
      ],
    );
  }

  Widget _buildMensaje({
    required IconData icono,
    required String titulo,
    required String detalle,
  }) {
    // ListView y no Column, para que el gesto de "tirar para recargar" funcione
    // también cuando no hay nada que mostrar.
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        Icon(icono, size: 56, color: const Color(0xFF90A4BA)),
        const SizedBox(height: 20),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: GoogleFonts.barlow(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          detalle,
          textAlign: TextAlign.center,
          style: GoogleFonts.questrial(
            fontSize: 14,
            color: const Color(0xFF90A4BA),
          ),
        ),
      ],
    );
  }

  Widget _buildTarjeta(RegistrationModel reg) {
    final formato = DateFormat('dd/MM/yyyy');
    final fecha =
        reg.eventStartDate != null ? formato.format(reg.eventStartDate!) : '';

    return Container(
      key: Key('credencial-${reg.eventId}'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A5F).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reg.eventTitle,
            style: GoogleFonts.barlow(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [fecha, reg.eventLocation].where((v) => v != null && v.isNotEmpty).join(' • '),
            style: GoogleFonts.questrial(
              fontSize: 13,
              color: const Color(0xFF90A4BA),
            ),
          ),
          const SizedBox(height: 16),
          if (reg.tieneQr)
            _buildQr(reg)
          else
            _buildSinQr(reg),
        ],
      ),
    );
  }

  Widget _buildQr(RegistrationModel reg) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: reg.qrData,
              version: QrVersions.auto,
              size: 190,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (reg.attendanceConfirmed)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.greenAccent, size: 18),
              const SizedBox(width: 6),
              Text(
                'Asistencia registrada',
                style: GoogleFonts.questrial(
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSinQr(RegistrationModel reg) {
    // El backend no manda el código de una inscripción sin pagar: no da derecho
    // a entrar, así que se explica en vez de enseñar un hueco.
    final pendiente = reg.estaPendienteDePago;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF13304A).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            pendiente ? Icons.schedule_rounded : Icons.qr_code_2_rounded,
            color: const Color(0xFFD9A74A),
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            pendiente ? 'Pendiente de pago' : 'Sin código disponible',
            style: GoogleFonts.barlow(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFD9A74A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pendiente
                ? 'Tu cupo está reservado. Cuando se confirme el pago aparecerá aquí tu código de acceso.'
                : 'Escríbenos si necesitas tu código de acceso para este evento.',
            textAlign: TextAlign.center,
            style: GoogleFonts.questrial(
              fontSize: 13,
              color: const Color(0xFF90A4BA),
            ),
          ),
        ],
      ),
    );
  }
}
