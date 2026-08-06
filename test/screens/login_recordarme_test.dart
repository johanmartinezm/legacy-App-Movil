import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:legacy_app/data/config/config_service.dart';
import 'package:legacy_app/domain/providers/auth_provider.dart';
import 'package:legacy_app/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';

/// `AuthProvider` real toca `flutter_secure_storage`, que no existe en las
/// pruebas; se neutraliza lo que la pantalla llama al construirse.
class _AuthFake extends AuthProvider {
  @override
  Future<String?> getSavedEmail() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await ConfigService.initialize();
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _AuthFake(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
  }

  bool marcada(WidgetTester tester) {
    return tester.widget<Checkbox>(find.byType(Checkbox)).value ?? false;
  }

  testWidgets('Empieza desmarcada', (tester) async {
    await montar(tester);
    expect(marcada(tester), isFalse);
  });

  testWidgets('Un toque sobre la casilla la marca, y otro la desmarca', (
    tester,
  ) async {
    // Antes el Checkbox vivía dentro de un GestureDetector que alternaba el
    // mismo estado, así que el resultado dependía de dónde cayera el dedo.
    await montar(tester);

    await tester.tap(find.byType(Checkbox), warnIfMissed: false);
    await tester.pump();
    expect(marcada(tester), isTrue, reason: 'un toque debe marcarla');

    await tester.tap(find.byType(Checkbox), warnIfMissed: false);
    await tester.pump();
    expect(marcada(tester), isFalse, reason: 'el segundo toque la desmarca');
  });

  testWidgets('Tocar el texto "Recordarme" tiene el mismo efecto', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.text('Recordarme'));
    await tester.pump();
    expect(marcada(tester), isTrue);

    await tester.tap(find.text('Recordarme'));
    await tester.pump();
    expect(marcada(tester), isFalse);
  });

  testWidgets('Toda la fila responde, no solo la casilla', (tester) async {
    await montar(tester);

    await tester.tap(find.byKey(const Key('login-recordarme')));
    await tester.pump();
    expect(marcada(tester), isTrue);
  });
}
