import 'config_service.dart';

class ApiConstants {
  static String get baseUrl => ConfigService.apiBaseUrl;

  static const String registerEndpoint = '/register';
  static const String loginEndpoint = '/login';
  static const String forgotPasswordEndpoint = '/forgot-password';
  static const String socialLoginEndpoint = '/api/auth/social-login';
  static const String resendVerificationEndpoint = '/api/auth/resend-verification';
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

  static const String getAgendaEndpoint = '/api/events/agenda';
  static String addToAgendaEndpoint(String id) => '/api/workshops/$id/agenda';
  static String removeFromAgendaEndpoint(String id) =>
      '/api/workshops/$id/agenda';

  // Custom Content
  static const String contentItemsEndpoint = '/api/content/items';
  static const String contentCategoriesEndpoint = '/api/content/categories';
}
