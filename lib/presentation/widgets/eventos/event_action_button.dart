import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/event_model.dart';
import '../../../domain/models/registration_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/events_provider.dart';
import '../../screens/eventos/event_payment_screen.dart';

/// Botón de acción del detalle de un evento: reservar, o el estado de la
/// inscripción si el usuario ya la tiene.
///
/// Antes esto se decidía con `event.actionStatus == 'registered'`, pero
/// `action_status` es una columna **del evento**, igual para todos los usuarios,
/// y el backend solo devuelve `register` o `buy`. La condición nunca se cumplía:
/// el mensaje "YA ESTÁS REGISTRADO" era inalcanzable y un usuario ya inscrito
/// seguía viendo "Reservar cupo".
class EventActionButton extends StatefulWidget {
  final EventModel event;

  const EventActionButton({super.key, required this.event});

  @override
  State<EventActionButton> createState() => _EventActionButtonState();
}

class _EventActionButtonState extends State<EventActionButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<EventsProvider>();
    if (provider.registrationsLoaded) return;
    await provider.loadMyRegistrations(token);
  }

  Future<void> _reservarGratis() async {
    final provider = context.read<EventsProvider>();
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final ok = await provider.registerUserToEvent(widget.event.id, token);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '¡Registro exitoso! Ya puedes ver tu credencial.'
              : 'Error: ${provider.errorMessage ?? "no pudimos reservar tu cupo"}',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final RegistrationModel? inscripcion =
        provider.registrationFor(widget.event.id);

    // Mientras no se sepa si está inscrito, no se le ofrece reservar un cupo
    // que quizá ya tiene.
    if (!provider.registrationsLoaded && inscripcion == null) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (inscripcion != null) {
      return inscripcion.estaPendienteDePago
          ? _buildPendientePago()
          : _buildYaInscrito();
    }

    return _buildReservar(provider.isLoading);
  }

  Widget _buildYaInscrito() {
    return Column(
      children: [
        Container(
          key: const Key('evento-ya-inscrito'),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: Text(
              'YA ESTÁS REGISTRADO',
              style: GoogleFonts.barlow(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF90A4BA),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: TextButton.icon(
            onPressed: () => context.push('/mi-credencial'),
            icon: const Icon(Icons.qr_code, size: 18),
            label: Text(
              'Ver mi credencial',
              style: GoogleFonts.barlow(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD9A74A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendientePago() {
    return Column(
      children: [
        Container(
          key: const Key('evento-pendiente-pago'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF13304A).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'CUPO RESERVADO · PENDIENTE DE PAGO',
                textAlign: TextAlign.center,
                style: GoogleFonts.barlow(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD9A74A),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completa el pago para recibir tu código de acceso.',
                textAlign: TextAlign.center,
                style: GoogleFonts.questrial(
                  fontSize: 12,
                  color: const Color(0xFF90A4BA),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventPaymentScreen(event: widget.event),
              ),
            ),
            style: _estiloDorado(),
            child: Text(
              'Completar pago',
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReservar(bool cargando) {
    final gratis = widget.event.isFree;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const Key('evento-reservar'),
        onPressed: cargando
            ? null
            : () {
                if (gratis) {
                  _reservarGratis();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventPaymentScreen(event: widget.event),
                    ),
                  );
                }
              },
        style: _estiloDorado(),
        child: cargando
            ? const CircularProgressIndicator(color: Color(0xFF050B15))
            : Text(
                gratis ? 'Reservar cupo gratis' : 'Reservar cupo · preventa',
                style: GoogleFonts.barlow(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  ButtonStyle _estiloDorado() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFD9A74A),
      foregroundColor: const Color(0xFF050B15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }
}
