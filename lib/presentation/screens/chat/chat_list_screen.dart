import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/providers/chat_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../widgets/custom_section_header.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatProvider>().loadConnections());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/comunidad-miembros'),
        backgroundColor: AppTheme.legacyBlue1,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CustomSectionHeader(
              title: 'CHAT DE CEOS',
              showBackButton: true,
            ),
            Expanded(
              child: Consumer2<ChatProvider, AuthProvider>(
                builder: (context, chatProvider, authProvider, child) {
                  if (chatProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (chatProvider.connections.isEmpty) {
                    return _buildEmptyState();
                  }

                  final myId = authProvider.userID;

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.connections.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conn = chatProvider.connections[index];
                      final isAccepted = conn.status == 'ACCEPTED';
                      final isReceiver = conn.receiverId == myId;

                      return ListTile(
                        onTap: isAccepted
                            ? () {
                                final name = conn.otherUser != null
                                    ? '${conn.otherUser!['first_name'] ?? 'CEO'} ${conn.otherUser!['last_name'] ?? ''}'
                                    : 'CEO Connection';
                                context.push(
                                  '/individual-chat/${conn.id}?title=$name',
                                );
                              }
                            : null,
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.legacyBlue2.withValues(alpha: 
                            0.1,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.legacyBlue2,
                          ),
                        ),
                        title: Text(
                          conn.otherUser != null
                              ? '${conn.otherUser!['first_name'] ?? 'CEO'} ${conn.otherUser!['last_name'] ?? ''}'
                              : 'CEO Connection',
                          style: GoogleFonts.questrial(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          isAccepted
                              ? 'Haga clic para chatear'
                              : (isReceiver
                                    ? 'Te han invitado a conectar'
                                    : 'Pendiente de aceptación'),
                          style: GoogleFonts.questrial(
                            color: isAccepted ? Colors.grey : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                        trailing:
                            !isAccepted &&
                                conn.status == 'PENDING' &&
                                isReceiver
                            ? IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () =>
                                    chatProvider.acceptInvite(conn.id),
                              )
                            : (isAccepted
                                  ? const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                    )
                                  : const Icon(
                                      Icons.hourglass_empty,
                                      size: 14,
                                      color: Colors.grey,
                                    )),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              'Aún no tienes chats',
              style: GoogleFonts.barlow(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Invita a otros miembros de la comunidad para iniciar una conversación de confianza.',
              textAlign: TextAlign.center,
              style: GoogleFonts.questrial(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
