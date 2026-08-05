import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_theme.dart';
import '../../../domain/models/event_survey_model.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/events_provider.dart';

/// Encuesta general del evento. Una sola respuesta por persona: si ya la envió,
/// el diálogo muestra lo que respondió en vez del formulario.
///
/// Distinta de [RatingDialog], que califica una charla suelta.
class EventSurveyDialog extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const EventSurveyDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventSurveyDialog> createState() => _EventSurveyDialogState();
}

class _EventSurveyDialogState extends State<EventSurveyDialog> {
  double _overall = 0;
  double _organization = 0;
  double _content = 0;
  double _speakers = 0;
  bool? _wouldRecommend;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_overall == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Danos al menos tu calificación general'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final eventsProvider = context.read<EventsProvider>();
    final token = context.read<AuthProvider>().token;

    if (token == null) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu sesión expiró. Vuelve a iniciar sesión.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Las opcionales sin tocar viajan como null, no como 0: el backend
    // distingue "sin responder" de una calificación baja.
    final survey = EventSurveyModel(
      id: '',
      eventId: widget.eventId,
      overallRating: _overall.round(),
      organizationRating: _organization == 0 ? null : _organization.round(),
      contentRating: _content == 0 ? null : _content.round(),
      speakersRating: _speakers == 0 ? null : _speakers.round(),
      wouldRecommend: _wouldRecommend,
      comment: _commentController.text,
    );

    final ok = await eventsProvider.submitEventSurvey(
      eventId: widget.eventId,
      survey: survey,
      token: token,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu opinión!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            eventsProvider.errorMessage ?? 'No pudimos enviar tu opinión',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = context.select<EventsProvider, EventSurveyModel?>(
      (p) => p.mySurveyFor(widget.eventId),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: existing != null
              ? _buildAlreadyAnswered(existing)
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildHeader(IconData icon, String title) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.legacyBlue1.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.legacyBlue1, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.barlow(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.legacyBlue1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.eventTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.barlow(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(Icons.rate_review_rounded, 'Cuéntanos tu experiencia'),
        const SizedBox(height: 24),
        _buildRatingRow(
          key: const Key('survey-overall'),
          label: 'En general',
          value: _overall,
          onChanged: (v) => setState(() => _overall = v),
          required: true,
        ),
        _buildRatingRow(
          key: const Key('survey-organization'),
          label: 'Organización',
          value: _organization,
          onChanged: (v) => setState(() => _organization = v),
        ),
        _buildRatingRow(
          key: const Key('survey-content'),
          label: 'Contenido',
          value: _content,
          onChanged: (v) => setState(() => _content = v),
        ),
        _buildRatingRow(
          key: const Key('survey-speakers'),
          label: 'Conferencistas',
          value: _speakers,
          onChanged: (v) => setState(() => _speakers = v),
        ),
        const SizedBox(height: 16),
        _buildRecommendRow(),
        const SizedBox(height: 20),
        TextField(
          key: const Key('survey-comment'),
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '¿Qué mejorarías? (opcional)',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.legacyBlue1,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            key: const Key('survey-submit'),
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.legacyBlue1,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Enviar opinión',
                    style: GoogleFonts.barlow(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Ahora no', style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _buildAlreadyAnswered(EventSurveyModel survey) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(Icons.check_circle_rounded, 'Ya enviaste tu opinión'),
        const SizedBox(height: 20),
        _buildReadOnlyRow('En general', survey.overallRating),
        _buildReadOnlyRow('Organización', survey.organizationRating),
        _buildReadOnlyRow('Contenido', survey.contentRating),
        _buildReadOnlyRow('Conferencistas', survey.speakersRating),
        if (survey.wouldRecommend != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '¿Lo recomendarías?',
                  style: GoogleFonts.barlow(fontSize: 15),
                ),
                Text(
                  survey.wouldRecommend! ? 'Sí' : 'No',
                  style: GoogleFonts.barlow(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.legacyBlue1,
                  ),
                ),
              ],
            ),
          ),
        if (survey.comment != null && survey.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              survey.comment!,
              style: GoogleFonts.barlow(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.legacyBlue1,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Cerrar',
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

  Widget _buildReadOnlyRow(String label, int? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.barlow(fontSize: 15)),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < value ? Icons.star_rounded : Icons.star_border_rounded,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow({
    required Key key,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    bool required = false,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required ? '$label *' : label,
            style: GoogleFonts.barlow(
              fontSize: 15,
              fontWeight: required ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          RatingBar.builder(
            initialRating: value,
            minRating: 1,
            direction: Axis.horizontal,
            itemCount: 5,
            itemSize: 32,
            itemPadding: const EdgeInsets.symmetric(horizontal: 2),
            itemBuilder: (context, _) =>
                const Icon(Icons.star_rounded, color: Colors.amber),
            onRatingUpdate: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '¿Lo recomendarías?',
            style: GoogleFonts.barlow(fontSize: 15, color: Colors.grey[800]),
          ),
        ),
        ChoiceChip(
          key: const Key('survey-recommend-yes'),
          label: const Text('Sí'),
          selected: _wouldRecommend == true,
          onSelected: (s) => setState(() => _wouldRecommend = s ? true : null),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          key: const Key('survey-recommend-no'),
          label: const Text('No'),
          selected: _wouldRecommend == false,
          onSelected: (s) => setState(() => _wouldRecommend = s ? false : null),
        ),
      ],
    );
  }
}
