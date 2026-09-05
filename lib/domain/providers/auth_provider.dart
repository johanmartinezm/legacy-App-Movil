import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cliente **web** de Google del proyecto `app-legacy-848f1`.
///
/// No es secreto —viaja en cada petición de inicio de sesión y está en
/// `google-services.json`—, pero tiene que ser exactamente el mismo que valida
/// el backend en `firebase.google_client_id`, o los tokens se rechazan.
const _clienteWebDeGoogle =
    '728967438065-l1fkjhhnr998gvtrg6oga2somie10tp9.apps.googleusercontent.com';

/// Traduce lo que lanzan los SDK de Google y Apple a algo que se pueda leer.
///
/// Antes se ponía `e.toString()` directo en la pantalla, así que al cancelar el
/// selector de cuenta —algo normal, no un fallo— aparecía un recuadro rojo con
/// `GoogleSignInException(code: GoogleSignInExceptionCode.canceled, ...)`. Y un
/// proyecto mal configurado mostraba el `ApiException: 10` en crudo.
///
/// Devuelve `null` cuando la persona canceló: ahí no hay nada que avisar.
///
/// Vive fuera de `AuthProvider` porque es una función pura y así se puede
/// probar sin construir el provider, cuyo constructor arranca
/// `checkLoginStatus()` y necesita la configuración cargada.
String? mensajeDeErrorSocial(Object e) {
  // Se comprueba con `if` y no con `switch` a proposito: el paquete añade
  // codigos nuevos entre versiones, y un `switch` exhaustivo dejaria de
  // compilar en cada actualizacion por un mensaje de error.
  if (e is GoogleSignInException) {
    if (e.code == GoogleSignInExceptionCode.canceled) return null;

    const configuracion = {
      GoogleSignInExceptionCode.clientConfigurationError,
      GoogleSignInExceptionCode.providerConfigurationError,
    };
    if (configuracion.contains(e.code)) {
      // El caso clasico: la huella del certificado con que se firmo el APK no
      // esta registrada en Firebase. No es algo que el usuario pueda resolver,
      // pero el mensaje tiene que orientar a quien lo reporte.
      return 'El acceso con Google no está bien configurado en esta versión '
          'de la app. Avísanos y entra con tu correo mientras tanto.';
    }

    return 'No se pudo completar el acceso con Google. Inténtalo de nuevo.';
  }

  if (e is SignInWithAppleAuthorizationException) {
    if (e.code == AuthorizationErrorCode.canceled) return null;
    return 'No se pudo completar el acceso con Apple. Inténtalo de nuevo.';
  }

  if (e is SignInWithAppleNotSupportedException) {
    return 'Este dispositivo no admite el acceso con Apple. '
        'Entra con tu correo y contraseña.';
  }

  // Lo que venga del backend ya llega redactado desde `auth_service`.
  return e.toString().replaceAll('Exception: ', '');
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _customerStatus;
  String? _userID;
  String? _firstName;
  String? _lastName;
  String? _email;
  String? _phone;
  String? _role;
  String? _alias;

  /// Cuentas creadas por la carga masiva: su contraseña es el número de
  /// documento, así que la app las lleva a cambiarla antes de dejarlas entrar.
  /// Llega en `GET /api/me` —no en la respuesta del login, que solo trae el
  /// token—. Ver reports/20260826_plan_carga_masiva.md §2.5.
  bool _debeCambiarContrasena = false;

  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    checkLoginStatus();
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get customerStatus => _customerStatus;
  String? get userID => _userID;
  String? get firstName => _firstName;
  String? get lastName => _lastName;
  String? get email => _email;
  String? get phone => _phone;
  String? get role => _role;
  bool get debeCambiarContrasena => _debeCambiarContrasena;

  /// Nombre y apellido juntos, sin espacios sobrantes si falta alguno.
  /// `null` cuando no hay ninguno de los dos, para que quien lo use pueda
  /// distinguir "sin datos" de una cadena vacía.
  String? get fullName {
    final partes = [
      _firstName,
      _lastName,
    ].where((p) => p != null && p.trim().isNotEmpty).map((p) => p!.trim());
    return partes.isEmpty ? null : partes.join(' ');
  }
  String? get alias => _alias;

  /// Comprueba si un JWT ya caducó, leyendo su claim `exp` sin llamar al
  /// servidor.
  ///
  /// Hace falta porque el token del backend **dura 24 horas**
  /// (`auth_service.go:54`) y no hay refresh token. Sin esta comprobación, al
  /// día siguiente "Recordarme" metía al usuario en la app con un token muerto:
  /// `isAuthenticated` era true, el splash iba a `/home`, y todas las llamadas
  /// respondían 401 sin que nada lo explicara. Desde fuera parecía que la
  /// sesión recordada no servía.
  static bool tokenCaducado(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final partes = token.split('.');
      if (partes.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      );
      final exp = payload['exp'];
      // Un token sin `exp` no se puede juzgar aquí; se deja pasar y que decida
      // el servidor.
      if (exp is! int) return false;
      final vence = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(vence);
    } catch (_) {
      // Ilegible es inservible.
      return true;
    }
  }

  Future<void> checkLoginStatus() async {
    _token = await _storage.read(key: 'auth_token');

    // Una sesión caducada se limpia aquí, para que el usuario acabe en el login
    // en vez de en una app donde todo falla con 401.
    if (_token != null && tokenCaducado(_token)) {
      debugPrint('Sesión guardada caducada: se pide iniciar sesión de nuevo');
      _token = null;
      await _borrarDatosPersistidos();
      notifyListeners();
      return;
    }

    _customerStatus = await _storage.read(key: 'customer_status');
    _userID = await _storage.read(key: 'user_id');
    _firstName = await _storage.read(key: 'first_name');
    _lastName = await _storage.read(key: 'last_name');
    _email = await _storage.read(key: 'user_email');
    _phone = await _storage.read(key: 'user_phone');
    _role = await _storage.read(key: 'user_role');
    _alias = await _storage.read(key: 'user_alias');
    if (_token != null) {
      if (_customerStatus == null ||
          _userID == null ||
          _firstName == null ||
          _email == null) {
        await fetchProfile();
      } else {
        // Sin esperar: los datos guardados alcanzan para pintar la app, pero
        // `debe_cambiar_contrasena` es estado del servidor y no se persiste.
        // Sin este refresco, alguien que cerrara la app en la pantalla de
        // cambio obligatorio volvería a entrar sin la obligación. Cuando
        // llegue, el notifyListeners despierta al router.
        unawaited(fetchProfile());
      }
    }
    if (_token != null) {
      _registerDeviceToken();
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final profile = await _authService.getProfile(_token!);
      _customerStatus = profile['customer_status'];
      _userID = profile['id'];
      _firstName = profile['first_name'];
      _lastName = profile['last_name'];
      _email = profile['email'];
      _phone = profile['phone'];
      await _storage.write(key: 'customer_status', value: _customerStatus);
      await _storage.write(key: 'user_id', value: _userID);
      if (_firstName != null) {
        await _storage.write(key: 'first_name', value: _firstName);
      }
      if (_lastName != null) {
        await _storage.write(key: 'last_name', value: _lastName);
      }
      if (_email != null) {
        await _storage.write(key: 'user_email', value: _email);
      }
      if (_phone != null && _phone!.isNotEmpty) {
        await _storage.write(key: 'user_phone', value: _phone);
      }
      _alias = profile['alias'];
      if (_alias != null) {
        await _storage.write(key: 'user_alias', value: _alias);
      }
      // No se guarda en el almacenamiento seguro a propósito: es un estado del
      // servidor y quedarse con una copia vieja significaría o encerrar a quien
      // ya cambió la contraseña, o dejar pasar a quien no.
      _debeCambiarContrasena = profile['debe_cambiar_contrasena'] == true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  /// La llama la pantalla de cambio obligatorio al terminar. Evita depender de
  /// un `fetchProfile` que puede fallar por red justo después de cambiarla.
  void marcarContrasenaCambiada() {
    if (!_debeCambiarContrasena) return;
    _debeCambiarContrasena = false;
    notifyListeners();
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: 'user_email');
  }

  /// Borra del dispositivo todo lo que identifica la sesión. Se usa al cerrar
  /// sesión y cuando el usuario entra **sin** marcar "Recordarme": en ese caso
  /// la sesión vive solo en memoria y no debe sobrevivir a cerrar la app.
  Future<void> _borrarDatosPersistidos() async {
    const claves = [
      'auth_token',
      'user_email',
      'customer_status',
      'user_id',
      'first_name',
      'last_name',
      'user_phone',
      'user_role',
      'user_alias',
    ];
    for (final clave in claves) {
      await _storage.delete(key: clave);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? password, // optional for social
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
        googleId: googleId,
        appleId: appleId,
        location: location,
        bio: bio,
        companyName: companyName,
        jobTitle: jobTitle,
        country: country,
        identificationType: identificationType,
        identificationNumber: identificationNumber,
        customerStatus: customerStatus,
        birthDate: birthDate,
        generation: generation,
        industry: industry,
        interests: interests,
        role: role,
        termsAccepted: termsAccepted,
        dataSharingAccepted: dataSharingAccepted,
        isPublicProfile: isPublicProfile,
        allowMessagesFromStrangers: allowMessagesFromStrangers,
        showActivity: showActivity,
      );

      _isLoading = false;
      notifyListeners();
      return true; // Registration successful
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> handleSocialLogin(String provider) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? idToken;
      if (provider == 'google') {
        // serverClientId es el cliente **web** del proyecto, y sin él este
        // inicio de sesión no puede funcionar contra nuestro backend.
        //
        // Es quien decide el `aud` del idToken. Sin declararlo, en iOS el token
        // sale a nombre del cliente de iOS y en Android ni siquiera se emite,
        // mientras que el backend lo valida con
        // idtoken.Validate(ctx, idToken, cfg.firebase.google_client_id), que es
        // este de aquí: cualquier otro `aud` se rechaza como token inválido.
        await GoogleSignIn.instance.initialize(
          serverClientId: _clienteWebDeGoogle,
        );
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        idToken = googleAuth.idToken;
      } else if (provider == 'apple') {
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        );
        idToken = credential.identityToken;
      }

      if (idToken == null) throw Exception('No se pudo obtener el token social');

      final response = await _authService.socialLogin(provider, idToken);
      
      if (response['statusCode'] == 404 || response['statusCode'] == 403) {
        // User not registered, return data to pre-fill registration
        _isLoading = false;
        notifyListeners();
        return {
          'action': 'register',
          'email': response['email'],
          'name': response['name'],
          'provider': provider,
          'id_token': idToken,
        };
      }

      // Success Login
      _token = response['token'];
      // El acceso con Google o Apple persiste siempre la sesión: la casilla
      // "Recordarme" pertenece al formulario de correo y contraseña.
      await _storage.write(key: 'auth_token', value: _token);
      await fetchProfile();
      if (_token != null) _registerDeviceToken();
      
      _isLoading = false;
      notifyListeners();
      return {'action': 'login'};

    } catch (e) {
      _isLoading = false;
      _errorMessage = mensajeDeErrorSocial(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(email, password);
      _token = response['token'];

      // Fetch profile to get customerStatus and userID
      final profile = await _authService.getProfile(_token!);
      _customerStatus = profile['customer_status'];
      _userID = profile['id'];
      _firstName = profile['first_name'];
      _lastName = profile['last_name'];
      _email = profile['email'] ?? email;
      _role = profile['role'];
      // El alias tambien: sin esta linea, `_alias` se quedaba en null despues
      // de iniciar sesion y la pantalla de foros
      // (forums_list_screen.dart:29) pedia configurar uno **a quien ya lo
      // tenia**. `fetchProfile` si lo leia, por eso el fallo solo aparecia
      // justo despues del login. Comprobado el 2026-09-04 contra produccion:
      // la cuenta traia alias en /api/me y la app mostraba el dialogo igual.
      _alias = profile['alias'];
      _debeCambiarContrasena = profile['debe_cambiar_contrasena'] == true;

      if (rememberMe) {
        await _storage.write(key: 'auth_token', value: _token);
        await _storage.write(key: 'user_email', value: _email);
        await _storage.write(key: 'customer_status', value: _customerStatus);
        await _storage.write(key: 'user_id', value: _userID);
        if (_firstName != null) {
          await _storage.write(key: 'first_name', value: _firstName);
        }
        if (_lastName != null) {
          await _storage.write(key: 'last_name', value: _lastName);
        }
        if (_role != null) {
          await _storage.write(key: 'user_role', value: _role);
        }
        if (_alias != null) {
          await _storage.write(key: 'user_alias', value: _alias);
        }
      } else {
        _email = email;
        await _borrarDatosPersistidos();
      }

      _isLoading = false;
      notifyListeners();
      _registerDeviceToken();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerificationEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resendVerificationEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Elimina la cuenta y deja la sesión cerrada.
  ///
  /// El cierre de sesión se hace SIEMPRE que el servidor confirme el borrado:
  /// quedarse con un token de una cuenta que ya no existe solo produce errores
  /// confusos en la siguiente pantalla. Si el servidor falla, no se toca nada
  /// local y el error sube para que la pantalla lo muestre.
  Future<void> deleteAccount() async {
    final token = _token;
    if (token == null) {
      throw Exception('No hay sesión activa.');
    }

    await _authService.deleteAccount(token);
    await logout();
  }

  Future<void> logout() async {
    _token = null;
    _customerStatus = null;
    _userID = null;
    _firstName = null;
    _lastName = null;
    _email = null;
    _phone = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'customer_status');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'first_name');
    await _storage.delete(key: 'last_name');
    await _storage.delete(key: 'user_phone');
    await _storage.delete(key: 'user_role');
    notifyListeners();
  }

  Future<void> _registerDeviceToken() async {
    if (_token == null) return;
    try {
      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        final deviceType = Platform.isIOS ? 'ios' : 'android';
        await _authService.registerFCMToken(fcmToken, deviceType, _token!);
        debugPrint('FCM Token registrado en backend: $fcmToken');
      }
    } catch (e) {
      debugPrint('Error al registrar token FCM: $e');
    }
  }
}
