import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/providers/auth_provider.dart';

/// Diálogo de eliminación de cuenta.
///
/// Existe porque App Store (directriz 5.1.1(v), desde junio de 2022) y Google
/// Play exigen que toda app con registro permita eliminar la cuenta **desde la
/// propia app**. Sin esto, ninguna de las dos tiendas acepta la publicación.
///
/// Pide escribir ELIMINAR y no un simple "¿seguro?": la acción no se puede
/// deshacer y un toque accidental en la lista del perfil no debería bastar.
class EliminarCuentaDialog extends StatefulWidget {
  const EliminarCuentaDialog({super.key});

  @override
  State<EliminarCuentaDialog> createState() => _EliminarCuentaDialogState();
}

class _EliminarCuentaDialogState extends State<EliminarCuentaDialog> {
  final _controlador = TextEditingController();
  bool _enviando = false;
  String? _error;

  static const _palabraClave = 'ELIMINAR';

  bool get _puedeConfirmar =>
      _controlador.text.trim().toUpperCase() == _palabraClave && !_enviando;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().deleteAccount();
      if (!mounted) return;
      // La sesión ya quedó cerrada en el provider: se vuelve al login.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // AlertDialog no desplaza su content por defecto: lo mete en un Flexible
      // que lo comprime. Con el teclado abierto, el campo donde hay que
      // escribir ELIMINAR quedaba fuera de la pantalla.
      scrollable: true,
      title: Text(
        'Eliminar mi cuenta',
        style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Se eliminarán tus datos personales: nombre, correo, teléfono y '
            'perfil. Esta acción no se puede deshacer.',
            style: GoogleFonts.questrial(fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Se dice lo que NO se borra, y por qué. Prometer un borrado total y
          // conservar registros seria enganar; y quien pregunte por sus
          // inscripciones a eventos ya pagados merece saber que siguen ahi.
          Text(
            'Tus inscripciones a eventos y los mensajes que enviaste se '
            'conservan sin tu nombre, porque forman parte del historial de '
            'otras personas y de eventos ya pagados.',
            style: GoogleFonts.questrial(fontSize: 13, color: const Color(0xFF6B7A8D)),
          ),
          const SizedBox(height: 16),
          Text(
            'Escribe $_palabraClave para confirmar:',
            style: GoogleFonts.questrial(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controlador,
            enabled: !_enviando,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: _palabraClave,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: GoogleFonts.questrial(fontSize: 13, color: Colors.red.shade700),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: _puedeConfirmar ? _eliminar : null,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Eliminar cuenta'),
        ),
      ],
    );
  }
}
