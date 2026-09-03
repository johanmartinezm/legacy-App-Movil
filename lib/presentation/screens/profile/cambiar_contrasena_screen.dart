import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/services/auth_service.dart';
import '../../../domain/providers/auth_provider.dart';

/// Cambio de contraseña **obligatorio**, para las cuentas que entran por una
/// carga masiva.
///
/// A esas cuentas se les asigna como contraseña su número de documento, que no
/// es un secreto: aparece en el archivo que se importó y lo conoce cualquiera
/// que lo haya manipulado. Por eso el backend marca
/// `debe_cambiar_contrasena` y el router trae aquí a quien la tenga puesta,
/// sin salida hasta cambiarla.
///
/// No es la misma que el diálogo de «Cambiar contraseña» de editar perfil, que
/// es voluntario y se puede cerrar. Ver
/// reports/20260826_plan_carga_masiva.md §2.5.
class CambiarContrasenaScreen extends StatefulWidget {
  /// Se inyecta solo en las pruebas, como en `PaginaInformativaScreen`: en la
  /// app va siempre el servicio de verdad.
  final AuthService? servicio;

  const CambiarContrasenaScreen({super.key, this.servicio});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualController = TextEditingController();
  final _nuevaController = TextEditingController();
  final _confirmaController = TextEditingController();

  bool _enviando = false;

  /// El mismo mínimo que exige el backend (`domain.LongitudMinimaContrasena`).
  /// Comprobarlo aquí solo ahorra un viaje; el que manda es el del servidor.
  static const int _minimo = 6;

  @override
  void dispose() {
    _actualController.dispose();
    _nuevaController.dispose();
    _confirmaController.dispose();
    super.dispose();
  }

  Future<void> _cambiar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await (widget.servicio ?? AuthService()).changePassword(
        authProvider.token!,
        _actualController.text,
        _nuevaController.text,
      );

      if (!mounted) return;
      // Se levanta la obligación sin volver a preguntarle al servidor: si la
      // red falla justo aquí, la persona quedaría encerrada en esta pantalla
      // con la contraseña ya cambiada.
      authProvider.marcarContrasenaCambiada();
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sin flecha y sin botón físico de atrás: no hay a dónde ir hasta cambiarla.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cambia tu contraseña'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Por seguridad, elige una contraseña nueva',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu cuenta se creó con una contraseña temporal: tu número '
                    'de documento. Cámbiala para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _actualController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                      helperText: 'Es tu número de documento',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Escribe tu contraseña actual'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nuevaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña nueva',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.length < _minimo) {
                        return 'Al menos $_minimo caracteres';
                      }
                      if (v == _actualController.text) {
                        return 'Tiene que ser distinta de la actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Repite la contraseña nueva',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v != _nuevaController.text
                        ? 'Las dos contraseñas no coinciden'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _enviando ? null : _cambiar,
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar y continuar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
