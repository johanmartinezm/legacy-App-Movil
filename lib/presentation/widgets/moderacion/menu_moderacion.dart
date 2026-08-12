import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/providers/block_provider.dart';
import 'reportar_usuario_dialog.dart';

/// Menú de moderación sobre otra persona: reportar y bloquear.
///
/// Vive en un solo sitio a propósito. La directriz 1.2 de Apple pide que estas
/// dos acciones estén donde ocurre el contacto —el chat, el directorio, un
/// perfil—, y tenerlas duplicadas en cada pantalla acabaría con textos
/// distintos según por dónde se entre.
///
/// Devuelve `true` si la persona quedó bloqueada, para que la pantalla que lo
/// abrió pueda salir de la conversación o refrescar su lista.
Future<bool> mostrarMenuModeracion(
  BuildContext context, {
  required String userId,
  required String userName,
  String? messageId,
}) async {
  final bloqueado = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Colors.orange),
            title: Text('Reportar', style: GoogleFonts.barlow()),
            subtitle: Text(
              'El equipo revisará lo ocurrido',
              style: GoogleFonts.barlow(fontSize: 12),
            ),
            onTap: () => Navigator.of(sheetContext).pop(false),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: Text('Bloquear', style: GoogleFonts.barlow()),
            subtitle: Text(
              'No podréis escribiros ni veros en la comunidad',
              style: GoogleFonts.barlow(fontSize: 12),
            ),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (bloqueado == null || !context.mounted) return false;

  if (bloqueado) {
    return await _confirmarBloqueo(context, userId: userId, userName: userName);
  }

  final reportado = await showDialog<bool>(
    context: context,
    builder: (_) => ReportarUsuarioDialog(
      userId: userId,
      userName: userName,
      messageId: messageId,
    ),
  );

  if (reportado == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reporte enviado. Gracias por avisarnos.'),
        backgroundColor: Colors.green,
      ),
    );
  }
  return false;
}

/// El bloqueo se confirma porque corta la conversación en los dos sentidos, y
/// se dice explícitamente qué pasa con los mensajes: no se borran. Prometer un
/// borrado que no ocurre sería engañar, y quien bloquea a veces necesita
/// conservar lo que le escribieron.
Future<bool> _confirmarBloqueo(
  BuildContext context, {
  required String userId,
  required String userName,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      // Son seis líneas de texto: con la fuente ampliada por accesibilidad no
      // caben en el alto que AlertDialog concede al content.
      scrollable: true,
      title: Text(
        '¿Bloquear a $userName?',
        style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• No podréis escribiros.\n'
            '• Dejaréis de veros en el directorio de la comunidad.\n'
            '• Vuestra conversación se ocultará, pero los mensajes no se '
            'borran: si le desbloqueas, volverá tal como está.',
            style: GoogleFonts.barlow(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            'Puedes deshacerlo cuando quieras desde Perfil › Cuentas '
            'bloqueadas.',
            style: GoogleFonts.barlow(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Bloquear', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirmado != true || !context.mounted) return false;

  final provider = context.read<BlockProvider>();
  final ok = await provider.blockUser(userId);

  if (!context.mounted) return ok;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? '$userName ha sido bloqueado' : (provider.error ?? 'No se pudo bloquear'),
      ),
      backgroundColor: ok ? Colors.green : Colors.red,
    ),
  );
  return ok;
}
