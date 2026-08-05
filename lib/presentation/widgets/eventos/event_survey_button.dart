import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/event_survey_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/events_provider.dart';
import 'event_survey_dialog.dart';

/// Acceso a la encuesta general desde el detalle de un evento ya terminado.
///
/// Se encarga de consultar por su cuenta si el usuario ya respondió, para que la
/// pantalla que lo contiene pueda seguir siendo un `StatelessWidget`.
class EventSurveyButton extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventSurveyButton({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventSurveyButton> createState() => _EventSurveyButtonState();
}

class _EventSurveyButtonState extends State<EventSurveyButton> {
  @override
  void initState() {
    super.initState();
    // Fuera del build: notifyListeners durante el primer frame revienta.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<EventsProvider>().loadMyEventSurvey(
      eventId: widget.eventId,
      token: token,
    );
  }

  void _open() {
    showDialog(
      context: context,
      builder: (_) => EventSurveyDialog(
        eventId: widget.eventId,
        eventTitle: widget.eventTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventsProvider>();
    final EventSurveyModel? mine = provider.mySurveyFor(widget.eventId);
    final yaRespondio = mine != null;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        key: const Key('event-survey-button'),
        onPressed: _open,
        icon: Icon(
          yaRespondio ? Icons.check_circle_rounded : Icons.rate_review_rounded,
          size: 20,
        ),
        label: Text(
          yaRespondio ? 'Ver tu opinión' : 'Califica este evento',
          style: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: yaRespondio
              ? const Color(0xFF0B1A2E)
              : const Color(0xFFD9A74A),
          foregroundColor: yaRespondio
              ? const Color(0xFF90A4BA)
              : const Color(0xFF050B15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
