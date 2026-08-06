import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  Future<void> checkLoginStatus() async {
    _token = await _storage.read(key: 'auth_token');
    _customerStatus = await _storage.read(key: 'customer_status');
    _userID = await _storage.read(key: 'user_id');
    _firstName = await _storage.read(key: 'first_name');
    _lastName = await _storage.read(key: 'last_name');
    _email = await _storage.read(key: 'user_email');
    _phone = await _storage.read(key: 'user_phone');
    _role = await _storage.read(key: 'user_role');
    _alias = await _storage.read(key: 'user_alias');
    if (_token != null && (_customerStatus == null || _userID == null || _firstName == null || _email == null)) {
      await fetchProfile();
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
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

  Future<Map<String, dynamic>?> handleSocialLogin(
    String provider, {
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? idToken;
      if (provider == 'google') {
        await GoogleSignIn.instance.initialize();
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
      // Se respeta "Recordarme" igual que en el login por correo. Antes el
      // token se guardaba SIEMPRE aquí, así que para quien entraba con Google o
      // Apple la casilla no hacía absolutamente nada: ni marcada ni desmarcada
      // cambiaba el comportamiento.
      if (rememberMe) {
        await _storage.write(key: 'auth_token', value: _token);
      } else {
        await _storage.delete(key: 'auth_token');
      }
      await fetchProfile();
      if (!rememberMe) {
        // fetchProfile persiste los datos del perfil; si no hay que recordar la
        // sesión, tampoco deben quedarse en el dispositivo.
        await _borrarDatosPersistidos();
      }
      if (_token != null) _registerDeviceToken();
      
      _isLoading = false;
      notifyListeners();
      return {'action': 'login'};

    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
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
