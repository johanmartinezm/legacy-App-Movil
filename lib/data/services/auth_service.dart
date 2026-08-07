import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    // Add other fields as per backend requirement
    String? password, // Now optional
    String? googleId,
    String? appleId,
    String? location,
    String? bio,
    String? companyName,
    String? jobTitle,
    String? country,
    String? identificationType,
    String? identificationNumber,
    String? customerStatus,
    String? birthDate,
    String? generation,
    String? industry,
    List<String>? interests,
    String? role,
    bool termsAccepted = false,
    bool dataSharingAccepted = false,
    bool isPublicProfile = true,
    bool allowMessagesFromStrangers = true,
    bool showActivity = true,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}',
    );

    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password': password,
      'location': location ?? '',
      'bio': bio ?? '',
      'company_name': companyName ?? '',
      'job_title': jobTitle ?? '',
      'country': country ?? '',
      'identification_type': identificationType ?? '',
      'identification_number': identificationNumber ?? '',
      'customer_status': customerStatus ?? '',
      'birth_date': birthDate ?? '',
      'generation': generation ?? '',
      'industry': industry ?? '',
      'interests': interests ?? [],
      'role': role ?? 'familia',
      'terms_accepted': termsAccepted,
      'data_sharing_accepted': dataSharingAccepted,
      'is_public_profile': isPublicProfile,
      'allow_messages_from_strangers': allowMessagesFromStrangers,
      'show_activity': showActivity,
    };

    if (googleId != null) body['google_id'] = googleId;
    if (appleId != null) body['apple_id'] = appleId;
    if (password != null) body['password'] = password;

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        String message;
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? 'Error desconocido';
        } catch (_) {
          message = 'Error del servidor (${response.statusCode})';
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> socialLogin(String provider, String idToken) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.socialLoginEndpoint}',
    );

    final body = {'provider': provider, 'id_token': idToken};

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 404 || response.statusCode == 403) {
        // Return 404/403 data so Provider can route to register
        final decoded = jsonDecode(response.body);
        decoded['statusCode'] = response.statusCode; 
        return decoded;
      } else {
        String message;
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? 'Error desconocido';
        } catch (_) {
          message = 'Error del servidor (${response.statusCode})';
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}',
    );

    final body = {'email': email, 'password': password};

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Should contain token
      } else {
        String message;
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? 'Credenciales inválidas';
        } catch (_) {
          message = 'Error del servidor (${response.statusCode})';
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.meEndpoint}');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> userData,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.meEndpoint}');

    try {
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 409) {
        throw Exception('alias_in_use');
      } else {
        throw Exception('Error al actualizar perfil: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('alias_in_use')) {
        rethrow;
      }
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> changePassword(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.changePasswordEndpoint}',
    );

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        String message;
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? 'Error al cambiar contraseña';
        } catch (_) {
          message = 'Error del servidor (${response.statusCode})';
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Elimina la cuenta de quien tiene la sesión abierta.
  ///
  /// El servidor no recibe ningún identificador: lo toma del token. Mandarlo
  /// desde aquí permitiría borrar la cuenta de otra persona cambiando un campo.
  ///
  /// En el servidor la cuenta se **anonimiza**, no se borra: los mensajes de
  /// chat y las inscripciones a eventos ya cobrados se conservan sin datos
  /// personales, porque borrarlos dejaría a medias las conversaciones de la
  /// otra persona. El correo queda libre para volver a registrarse.
  Future<void> deleteAccount(String token) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.meEndpoint}');

    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      // 204 es la respuesta esperada; 200 se acepta por si el servidor
      // devolviera cuerpo algún día.
      if (response.statusCode == 204 || response.statusCode == 200) return;

      if (response.statusCode == 401) {
        throw Exception('Tu sesión expiró. Vuelve a entrar e inténtalo de nuevo.');
      }
      if (response.statusCode == 404) {
        throw Exception('Esta cuenta ya no existe.');
      }
      throw Exception('No se pudo eliminar la cuenta (${response.statusCode}).');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> forgotPassword(String email) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.forgotPasswordEndpoint}',
    );

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        String message;
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? 'Error al solicitar recuperación';
        } catch (_) {
          message = 'Error del servidor (${response.statusCode})';
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.resendVerificationEndpoint}',
    );

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200) {
        String message;
        try {
          final errorBody = jsonDecode(response.body);
          message = errorBody['message'] ?? 'Error al reenviar verificación';
        } catch (_) {
          message = 'Error del servidor (${response.statusCode})';
        }
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> registerFCMToken(String fcmToken, String deviceType, String authToken) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.fcmTokenEndpoint}',
    );

    final body = {
      'fcm_token': fcmToken,
      'device_type': deviceType,
    };

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al registrar token FCM: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en registerFCMToken: $e');
    }
  }
}
