import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/contacto_service.dart';
import '../../../domain/providers/auth_provider.dart';

/// Pantalla "Contactenos" del documento de alcance.
///
/// Ofrece las dos vias a proposito: el formulario deja constancia en el buzon
/// de soporte y no obliga a salir de la app, y los canales directos sirven
/// cuando el envio falla o la persona prefiere su propio correo.
class ContactoScreen extends StatefulWidget {
  const ContactoScreen({super.key});

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _mensajeController = TextEditingController();

  bool _enviando = false;
  bool _enviado = false;

  /// Mismos limites que valida el backend (`contacto_service.go`). Repetirlos
  /// aqui es para no gastar un viaje al servidor en un error previsible; el
  /// que cuenta es el del servidor.
  static const _maximoAsunto = 200;
  static const _maximoMensaje = 5000;

  static const _correoSoporte = 'soporte@legacynetworkco.com';
  static const _sitioWeb = 'https://legacynetworkco.com';

  @override
  void dispose() {
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await ContactoService().enviarMensaje(
        token: authProvider.token ?? '',
        asunto: _asuntoController.text.trim(),
        mensaje: _mensajeController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _enviando = false;
        _enviado = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          // El mensaje escrito no se borra al fallar: reescribirlo entero
          // seria la peor forma de enterarse de que no salio.
          action: SnackBarAction(
            label: 'Escribir por correo',
            textColor: Colors.white,
            onPressed: _abrirCorreo,
          ),
        ),
      );
    }
  }

  Future<void> _abrirCorreo() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _correoSoporte,
      queryParameters: {
        if (_asuntoController.text.trim().isNotEmpty) 'subject': _asuntoController.text.trim(),
        if (_mensajeController.text.trim().isNotEmpty) 'body': _mensajeController.text.trim(),
      },
    );
    await _abrir(uri, 'No se pudo abrir la aplicación de correo');
  }

  Future<void> _abrirWeb() async {
    await _abrir(Uri.parse(_sitioWeb), 'No se pudo abrir el sitio web');
  }

  Future<void> _abrir(Uri uri, String siFalla) async {
    // Un mailto sin cliente de correo configurado no lanza excepcion: devuelve
    // false y la pantalla se quedaria muda.
    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(siFalla)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contáctenos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _enviado ? _confirmacion(context) : _formulario(context),
        ),
      ),
    );
  }

  Widget _confirmacion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Icon(Icons.mark_email_read_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Mensaje enviado',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nuestro equipo lo revisará y le responderá al correo de su cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Volver'),
        ),
        TextButton(
          onPressed: () {
            _asuntoController.clear();
            _mensajeController.clear();
            setState(() => _enviado = false);
          },
          child: const Text('Escribir otro mensaje'),
        ),
      ],
    );
  }

  Widget _formulario(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿En qué podemos ayudarle?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escríbanos y le responderemos al correo de su cuenta.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _asuntoController,
            maxLength: _maximoAsunto,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Asunto',
              hintText: 'Por ejemplo: problema al inscribirme a un evento',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mensajeController,
            maxLines: 6,
            maxLength: _maximoMensaje,
            decoration: const InputDecoration(
              labelText: 'Mensaje',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Escriba su mensaje';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar mensaje'),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Otras formas de contacto',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.email_outlined),
            title: const Text('Correo'),
            subtitle: const Text(_correoSoporte),
            onTap: _abrirCorreo,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: const Text('Sitio web'),
            subtitle: const Text('legacynetworkco.com'),
            onTap: _abrirWeb,
          ),
        ],
      ),
    );
  }
}
