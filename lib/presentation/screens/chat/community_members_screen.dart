import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/providers/chat_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/custom_section_header.dart';
import '../../widgets/moderacion/menu_moderacion.dart';

class CommunityMembersScreen extends StatefulWidget {
  const CommunityMembersScreen({super.key});

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().loadMembers());
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().userID;

    return Scaffold(
      backgroundColor: const Color(0xFF050B15),
      body: SafeArea(
        child: Column(
          children: [
            const CustomSectionHeader(
              title: 'MIEMBROS DE LA COMUNIDAD',
              showBackButton: true,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Solo puedes chatear con miembros si ambos aceptan la conexión para garantizar la máxima confianza.',
                style: GoogleFonts.questrial(color: const Color(0xFF9FB2C2), fontSize: 13),
              ),
            ),

            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter out myself
                  final members = chatProvider.members
                      .where((m) => m.id != myId)
                      .toList();

                  if (members.isEmpty) {
                    return const Center(
                      child: Text('No hay otros miembros disponibles.', style: TextStyle(color: Colors.white)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.1)),
                    itemBuilder: (context, index) {
                      final member = members[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          child: Text(
                            member.firstName.isNotEmpty
                                ? member.firstName[0]
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          member.fullName,
                          style: GoogleFonts.barlow(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '${member.jobTitle} en ${member.companyName}',
                          style: GoogleFonts.questrial(fontSize: 12, color: const Color(0xFF9FB2C2)),
                        ),
                        // Mantener pulsado abre reportar y bloquear. Va aquí
                        // además de en el chat porque la directriz 1.2 pide
                        // poder actuar antes de aceptar contacto: sin esto,
                        // para bloquear a alguien habría que abrir primero una
                        // conversación con esa misma persona.
                        onLongPress: () async {
                          final bloqueado = await mostrarMenuModeracion(
                            context,
                            userId: member.id,
                            userName: member.fullName,
                          );
                          if (bloqueado) {
                            // El directorio ya no debe mostrarle: el backend lo
                            // filtra, así que basta con recargar.
                            await chatProvider.loadMembers();
                          }
                        },
                        trailing: ElevatedButton(
                          onPressed: () async {
                            try {
                              await chatProvider.sendInvite(member.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invitación de confianza enviada',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7FB2D9),
                            foregroundColor: const Color(0xFF050B15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text(
                            'Conectar',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
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
