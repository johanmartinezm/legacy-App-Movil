import 'config_service.dart';

class ApiConstants {
  static String get baseUrl => ConfigService.apiBaseUrl;

  static const String registerEndpoint = '/register';
  static const String loginEndpoint = '/login';
  static const String forgotPasswordEndpoint = '/forgot-password';
  static const String socialLoginEndpoint = '/api/auth/social-login';
  static const String resendVerificationEndpoint = '/api/auth/resend-verification';
  // Imagenes de los foros. Van bajo /api/ porque en produccion HAProxy solo
  // enruta ese prefijo al backend: pedirlas desde la raiz las mandaba al panel
  // Angular. El backend responde en las dos formas para no romper los builds
  // ya instalados.
  static const String imageUploadEndpoint = '/api/images/upload';
  static String imageUrl(String name) => '$baseUrl/api/images/$name';

  // Paginas de informacion que edita el panel (hoy, Legacy Board). Publicas:
  // no exigen sesion, igual que los banners.
  static String paginaEndpoint(String slug) => '/api/paginas/$slug';

  static const String meEndpoint = '/api/me';
  static const String changePasswordEndpoint = '/api/me/change-password';
  static const String fcmTokenEndpoint = '/api/me/fcm-token';

  static String likePostEndpoint(String id) => '/api/posts/$id/like';
  static String getLikesEndpoint(String id) => '/api/posts/$id/likes';
  static String recordViewEndpoint(String id) => '/api/posts/$id/view';

  static const String eventsEndpoint = '/api/events';
  static String eventDetailsEndpoint(String id) => '/api/events/$id';
  static String registerEventEndpoint(String id) => '/api/events/$id/register';
  static String workshopRatingEndpoint(String id) =>
      '/api/workshops/$id/rating';

  // Encuesta general del evento, distinta de la calificación por charla de
  // arriba. Una sola respuesta por persona y evento; el backend responde 409 al
  // segundo envío y 403 a quien no esté registrado.
  static String eventSurveyEndpoint(String id) => '/api/events/$id/survey';
  static String myEventSurveyEndpoint(String id) =>
      '/api/events/$id/survey/me';

  // Todos los eventos en los que el usuario está inscrito, cada uno con su QR.
  // Alimenta la pantalla "Mi credencial". Cuelga de /api/me y no de /api/events
  // porque el patrón /api/events/{id} captura cualquier segmento.
  static const String myRegistrationsEndpoint = '/api/me/registrations';

  static const String getAgendaEndpoint = '/api/events/agenda';
  static String addToAgendaEndpoint(String id) => '/api/workshops/$id/agenda';
  static String removeFromAgendaEndpoint(String id) =>
      '/api/workshops/$id/agenda';

  // Custom Content
  static const String contentItemsEndpoint = '/api/content/items';
  static const String contentCategoriesEndpoint = '/api/content/categories';

  /// Videos de los canales de YouTube de Legacy Network y LSO. Los sirve el
  /// backend, no la app: la clave de la API no puede viajar en el binario.
  static const String contentVideosEndpoint = '/api/content/videos';

  // Bloquear y reportar personas. Requisito de la directriz 1.2 de Apple para
  // cualquier app con chat o contenido publicado por sus usuarios.
  // Quién bloquea lo decide el servidor a partir del token; aquí solo va a quién.
  static const String blocksEndpoint = '/api/blocks';
  static String blockUserEndpoint(String userId) => '/api/blocks/$userId';
  static String reportUserEndpoint(String userId) => '/api/users/$userId/report';
}
