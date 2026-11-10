import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/widgets/foto_de_perfil.dart';
import 'package:provider/provider.dart';

/// «Mi perfil», Inicio y la cabecera pintaban un círculo vacío aunque la
/// persona tuviera foto (2026-11-10).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await ConfigService.initialize();
  });

  Widget pantalla(String? foto) => ChangeNotifierProvider<AuthProvider>.value(
        value: _AuthConFoto(foto),
        child: const MaterialApp(
          home: Scaffold(
            body: FotoDePerfil(
              tamano: 100,
              sinFoto: Text('sin foto'),
            ),
          ),
        ),
      );

  testWidgets('sin foto pinta el círculo de siempre', (tester) async {
    await tester.pumpWidget(pantalla(null));
    expect(find.text('sin foto'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('con foto pide la imagen al backend con la URL completa',
      (tester) async {
    await tester.pumpWidget(pantalla('/api/images/abc.jpg'));
    final imagen = tester.widget<Image>(find.byType(Image));
    final url = (imagen.image as NetworkImage).url;
    expect(url, startsWith('http'));
    expect(url, endsWith('/api/images/abc.jpg'));
  });
}

class _AuthConFoto extends AuthProvider {
  final String? _foto;
  _AuthConFoto(this._foto);

  @override
  String? get fotoPerfil => _foto;
}
