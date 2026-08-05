import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/models/event_survey_model.dart';

void main() {
  group('EventSurveyModel.toJson', () {
    test('Omite las opcionales sin responder', () {
      // El backend distingue "sin responder" (null) de una calificación baja.
      // Mandar 0 rompería además el CHECK de la tabla, que exige entre 1 y 5.
      const survey = EventSurveyModel(
        id: '',
        eventId: 'event-1',
        overallRating: 4,
      );

      final json = survey.toJson();

      expect(json, {'overallRating': 4});
      expect(json.containsKey('organizationRating'), isFalse);
      expect(json.containsKey('contentRating'), isFalse);
      expect(json.containsKey('speakersRating'), isFalse);
      expect(json.containsKey('wouldRecommend'), isFalse);
      expect(json.containsKey('comment'), isFalse);
    });

    test('Incluye las opcionales respondidas', () {
      const survey = EventSurveyModel(
        id: '',
        eventId: 'event-1',
        overallRating: 5,
        organizationRating: 4,
        contentRating: 3,
        speakersRating: 5,
        wouldRecommend: true,
        comment: 'Todo excelente',
      );

      expect(survey.toJson(), {
        'overallRating': 5,
        'organizationRating': 4,
        'contentRating': 3,
        'speakersRating': 5,
        'wouldRecommend': true,
        'comment': 'Todo excelente',
      });
    });

    test('Un "no lo recomendaría" viaja como false, no se omite', () {
      const survey = EventSurveyModel(
        id: '',
        eventId: 'event-1',
        overallRating: 2,
        wouldRecommend: false,
      );

      expect(survey.toJson()['wouldRecommend'], isFalse);
    });

    test('Recorta el comentario y omite el que queda vacío', () {
      const conEspacios = EventSurveyModel(
        id: '',
        eventId: 'event-1',
        overallRating: 4,
        comment: '   Muy bueno   ',
      );
      const enBlanco = EventSurveyModel(
        id: '',
        eventId: 'event-1',
        overallRating: 4,
        comment: '   \n  ',
      );

      expect(conEspacios.toJson()['comment'], 'Muy bueno');
      expect(enBlanco.toJson().containsKey('comment'), isFalse);
    });
  });

  group('EventSurveyModel.fromJson', () {
    test('Lee la respuesta del backend', () {
      final survey = EventSurveyModel.fromJson({
        'id': 'survey-1',
        'eventId': 'event-1',
        'userId': 'user-1',
        'overallRating': 5,
        'organizationRating': 4,
        'contentRating': 5,
        'speakersRating': null,
        'wouldRecommend': true,
        'comment': 'Todo excelente',
        'createdAt': '2026-08-05T18:25:04.003629-05:00',
      });

      expect(survey.id, 'survey-1');
      expect(survey.overallRating, 5);
      expect(survey.organizationRating, 4);
      expect(survey.speakersRating, isNull);
      expect(survey.wouldRecommend, isTrue);
      expect(survey.comment, 'Todo excelente');
      expect(survey.createdAt?.year, 2026);
    });

    test('Sobrevive a campos ausentes o de otro tipo', () {
      final survey = EventSurveyModel.fromJson({
        'id': 'survey-2',
        'overallRating': '3',
      });

      expect(survey.overallRating, 3);
      expect(survey.eventId, '');
      expect(survey.wouldRecommend, isNull);
      expect(survey.createdAt, isNull);
    });
  });

  group('EventSurveyException.fromStatusCode', () {
    test('Traduce cada código a un motivo distinguible', () {
      final casos = <int, EventSurveyError>{
        400: EventSurveyError.invalidRating,
        401: EventSurveyError.unauthorized,
        403: EventSurveyError.notRegistered,
        404: EventSurveyError.eventNotFound,
        409: EventSurveyError.alreadySubmitted,
        500: EventSurveyError.unknown,
      };

      casos.forEach((codigo, esperado) {
        final e = EventSurveyException.fromStatusCode(codigo, '');
        expect(e.reason, esperado, reason: 'para el codigo $codigo');
        expect(e.message, isNotEmpty);
      });
    });

    test('El mensaje del 403 explica que hay que estar registrado', () {
      final e = EventSurveyException.fromStatusCode(403, '');
      expect(e.message.toLowerCase(), contains('registraron'));
    });
  });
}
