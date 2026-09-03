import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../domain/providers/notification_provider.dart';
import '../../widgets/boton_volver.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    // Cuando se entra a la pantalla, marcar todas como leídas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (notificationProvider.unreadCount > 0) {
        notificationProvider.markAllAsRead();
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BotonVolver(),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.barlow(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF90A4BA)),
              tooltip: 'Limpiar todo',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF0B1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: const Color(0xFF2A4A75).withValues(alpha: 0.35)),
                    ),
                    title: Text(
                      'Limpiar notificaciones',
                      style: GoogleFonts.barlow(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      '¿Desea borrar todas las notificaciones recibidas?',
                      style: GoogleFonts.questrial(color: const Color(0xFF90A4BA)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar', style: GoogleFonts.questrial(color: Colors.white)),
                      ),
                      TextButton(
                        onPressed: () {
                          notificationProvider.clearAll();
                          Navigator.pop(context);
                        },
                        child: Text('Limpiar', style: GoogleFonts.questrial(color: const Color(0xFFE3C272), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      backgroundColor: const Color(0xFF050B15),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.8),
            radius: 1.5,
            colors: [
              Color(0xFF13304A),
              Color(0xFF0E2C3B),
              Color(0xFF050B15),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _buildNotificationCard(context, item);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE3C272).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFFE3C272),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin notificaciones',
            style: GoogleFonts.barlow(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te avisaremos cuando recibas novedades.',
            style: GoogleFonts.questrial(
              color: const Color(0xFF90A4BA),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification item) {
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(item.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2E).withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF2A4A75).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono indicativo de mensaje
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3C272).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFE3C272),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Contenido de la notificación
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: GoogleFonts.questrial(
                        color: const Color(0xFF90A4BA),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.body,
                  style: GoogleFonts.questrial(
                    color: const Color(0xFFFFF1CF).withValues(alpha: 0.9),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
