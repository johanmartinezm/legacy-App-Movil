import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Lo que lanzan los SDK de Google y Apple se pintaba tal cual en el recuadro
/// rojo del login. Cancelar el selector de cuenta —que no es un fallo— sacaba
/// `GoogleSignInException(code: GoogleSignInExceptionCode.canceled, ...)`, y un
/// proyecto mal configurado sacaba el `ApiException: 10` en crudo.
///
/// Estas pruebas fijan las dos propiedades que importan: cancelar no genera
/// aviso, y ningun mensaje deja escapar texto tecnico.
void main() {
  String? mensaje(Object e) => mensajeDeErrorSocial(e);

  group('cancelar no es un error', () {
    test('Google: cancelar no deja mensaje', () {
      expect(
        mensaje(const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
          description: 'user canceled',
        )),
        isNull,
      );
    });

    test('Apple: cancelar no deja mensaje', () {
      expect(
        mensaje(SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'user canceled',
        )),
        isNull,
      );
    });
  });

  group('los fallos se explican sin jerga', () {
    test('un proyecto mal configurado orienta a entrar por correo', () {
      final m = mensaje(const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'ApiException: 10',
      ));
      expect(m, isNotNull);
      expect(m, contains('correo'));
      // Lo que no puede pasar: filtrar el detalle tecnico a la pantalla.
      expect(m, isNot(contains('ApiException')));
      expect(m, isNot(contains('GoogleSignInException')));
    });

    test('un fallo cualquiera de Google invita a reintentar', () {
      final m = mensaje(const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'algo raro paso',
      ));
      expect(m, isNotNull);
      expect(m, isNot(contains('algo raro paso')));
    });

    test('un fallo de Apple invita a reintentar', () {
      final m = mensaje(SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'AKAuthenticationError -7026',
      ));
      expect(m, isNotNull);
      expect(m, isNot(contains('-7026')));
    });

    test('un dispositivo sin Apple manda al correo', () {
      final m = mensaje(const SignInWithAppleNotSupportedException(
        message: 'no soportado',
      ));
      expect(m, contains('correo'));
    });
  });

  test('los errores del backend pasan tal cual, ya vienen redactados', () {
    // `auth_service` ya traduce los fallos de red y de la API a algo legible;
    // volver a envolverlos aqui perderia ese trabajo.
    expect(
      mensaje(Exception('No hay conexión. Revisa tu red e inténtalo de nuevo.')),
      'No hay conexión. Revisa tu red e inténtalo de nuevo.',
    );
  });
}
