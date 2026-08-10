import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../domain/providers/block_provider.dart';
import '../../widgets/custom_section_header.dart';

/// Lista de personas bloqueadas, con la opción de desbloquear.
///
/// La directriz 1.2 de Apple pide poder bloquear; poder deshacerlo es lo que
/// hace que la función sea usable. Sin esta pantalla, un bloqueo por error sería
/// permanente y quien lo hizo no tendría forma de encontrar a esa persona: deja
/// de aparecer en el directorio precisamente por estar bloqueada.
class UsuariosBloqueadosScreen extends StatefulWidget {
  const UsuariosBloqueadosScreen({super.key});

  @override
  State<UsuariosBloqueadosScreen> createState() =>
      _UsuariosBloqueadosScreenState();
}

class _UsuariosBloqueadosScreenState extends State<UsuariosBloqueadosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<BlockProvider>().loadBlocked();
    });
  }

  Future<void> _desbloquear(String userId, String nombre) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '¿Desbloquear a $nombre?',
          style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Volveréis a veros en la comunidad y podréis escribiros. Si teníais '
          'una conversación, reaparecerá con sus mensajes.',
          style: GoogleFonts.barlow(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final provider = context.read<BlockProvider>();
    final ok = await provider.unblockUser(userId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? '$nombre ha sido desbloqueado' : (provider.error ?? 'No se pudo desbloquear'),
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: SafeArea(
        child: Column(
          children: [
            const CustomSectionHeader(
              title: 'CUENTAS BLOQUEADAS',
              showBackButton: true,
            ),
            Expanded(
              child: Consumer<BlockProvider>(
                builder: (context, provider, _) {
                  if (provider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.blocked.isEmpty) {
                    return _Aviso(
                      icono: Icons.error_outline,
                      titulo: 'No se pudo cargar la lista',
                      detalle: provider.error!,
                      accion: TextButton(
                        onPressed: provider.loadBlocked,
                        child: const Text('Reintentar'),
                      ),
                    );
                  }

                  if (provider.blocked.isEmpty) {
                    return const _Aviso(
                      icono: Icons.check_circle_outline,
                      titulo: 'No has bloqueado a nadie',
                      detalle:
                          'Puedes bloquear a alguien desde su chat o desde el '
                          'directorio de la comunidad.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.loadBlocked,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.blocked.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final b = provider.blocked[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: b.profileImageUrl.isNotEmpty
                                ? NetworkImage(b.profileImageUrl)
                                : null,
                            child: b.profileImageUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            b.displayName,
                            style: GoogleFonts.barlow(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () =>
                                _desbloquear(b.userId, b.displayName),
                            child: const Text('Desbloquear'),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? accion;

  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: GoogleFonts.barlow(color: Colors.grey.shade700),
            ),
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}
