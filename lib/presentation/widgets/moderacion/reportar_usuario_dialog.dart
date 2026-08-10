import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/providers/block_provider.dart';

/// Diálogo para reportar a una persona.
///
/// Existe por la directriz 1.2 de Apple: toda app con contenido publicado por
/// sus usuarios debe permitir **reportar** y **bloquear** desde la propia app.
///
/// Se ofrecen motivos predefinidos porque quien acaba de recibir un mensaje
/// desagradable no siempre quiere redactar nada, y un reporte sin motivo no le
/// sirve a quien tiene que revisarlo. Siempre queda la opción de escribirlo.
class ReportarUsuarioDialog extends StatefulWidget {
  final String userId;
  final String userName;

  /// Mensaje concreto que motiva el reporte, si viene de un chat.
  final String? messageId;

  const ReportarUsuarioDialog({
    super.key,
    required this.userId,
    required this.userName,
    this.messageId,
  });

  @override
  State<ReportarUsuarioDialog> createState() => _ReportarUsuarioDialogState();
}

class _ReportarUsuarioDialogState extends State<ReportarUsuarioDialog> {
  static const _motivos = [
    'Mensajes ofensivos o insultos',
    'Acoso o amenazas',
    'Contenido sexual no solicitado',
    'Spam o publicidad',
    'Suplantación de identidad',
  ];

  String? _motivoElegido;
  final _otroControlador = TextEditingController();
  bool _enviando = false;
  String? _error;

  bool get _esOtro => _motivoElegido == null;

  String get _motivoFinal =>
      _esOtro ? _otroControlador.text.trim() : _motivoElegido!;

  bool get _puedeEnviar => _motivoFinal.isNotEmpty && !_enviando;

  @override
  void dispose() {
    _otroControlador.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });

    final provider = context.read<BlockProvider>();
    final ok = await provider.reportUser(
      widget.userId,
      _motivoFinal,
      messageId: widget.messageId,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      // El diálogo NO se cierra si falla: lo peor sería que alguien creyera
      // haber reportado a quien le acosa cuando el reporte no llegó.
      setState(() {
        _enviando = false;
        _error = provider.error ?? 'No se pudo enviar el reporte';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Reportar a ${widget.userName}',
        style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuéntanos qué ha pasado. El equipo de Legacy Network revisará el '
              'reporte.',
              style: GoogleFonts.barlow(fontSize: 14),
            ),
            const SizedBox(height: 16),
            // ListTile con icono en vez de RadioListTile: la API de Radio con
            // groupValue/onChanged quedó deprecada en Flutter 3.32 y no merece
            // arrastrar el aviso por una lista de cinco opciones.
            ..._motivos.map(
              (m) => _OpcionMotivo(
                texto: m,
                seleccionada: _motivoElegido == m,
                onTap: _enviando
                    ? null
                    : () => setState(() => _motivoElegido = m),
              ),
            ),
            _OpcionMotivo(
              texto: 'Otro motivo',
              seleccionada: _esOtro,
              onTap: _enviando ? null : () => setState(() => _motivoElegido = null),
            ),
            if (_esOtro)
              TextField(
                controller: _otroControlador,
                enabled: !_enviando,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Describe qué ha ocurrido',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 8),
            Text(
              'Reportar no bloquea a esta persona. Si no quieres que vuelva a '
              'escribirte, bloquéala también.',
              style: GoogleFonts.barlow(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.barlow(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _puedeEnviar ? _enviar : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Enviar reporte',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

/// Una opción de motivo. Se pinta como un radio pero sin usar la API deprecada.
class _OpcionMotivo extends StatelessWidget {
  final String texto;
  final bool seleccionada;
  final VoidCallback? onTap;

  const _OpcionMotivo({
    required this.texto,
    required this.seleccionada,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        seleccionada ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: seleccionada ? Theme.of(context).primaryColor : Colors.grey,
        size: 20,
      ),
      title: Text(texto, style: GoogleFonts.barlow(fontSize: 14)),
    );
  }
}
