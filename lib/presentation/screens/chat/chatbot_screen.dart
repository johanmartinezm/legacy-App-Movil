import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../widgets/custom_section_header.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:legacy_app/domain/utils/sanitizar_html.dart';
import 'package:go_router/go_router.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(
      Message(
        text:
            '¡Hola! Soy el asistente virtual de Legacy. ¿En qué puedo ayudarte hoy?',
        isUser: false,
        time: TimeOfDay.now(),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(
        Message(text: userMessage, isUser: true, time: TimeOfDay.now()),
      );
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate bot response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            Message(
              text: _getBotResponse(userMessage),
              isUser: false,
              time: TimeOfDay.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  String _getBotResponse(String message) {
    message = message.toLowerCase();
    if (message.contains('hola') || message.contains('buenos días')) {
      return '¡Hola de nuevo! Es un gusto saludarte. ¿Tienes alguna duda sobre nuestros servicios o programas?';
    } else if (message.contains('asesoría') || message.contains('ayuda')) {
      return 'Para recibir asesoría personalizada, puedes <a href="internal:/asesoria"><b>pulsar aquí para ir a Asesoría</b></a> o decirme qué tema te interesa.';
    } else if (message.contains('programa') || message.contains('formación')) {
      return 'Nuestros programas de formación están diseñados para el crecimiento empresarial. Puedes verlos <a href="internal:/programas"><b>aquí</b></a> o consultarme algo puntual.';
    } else if (message.contains('libro') || message.contains('lectura')) {
      return 'Te recomiendo revisar nuestra sección de <a href="internal:/libros"><b>Libros</b></a>. Allí encontrarás material selecto sobre empresa familiar y estrategia.';
    } else if (message.contains('contacto') || message.contains('humano') || message.contains('asesor')) {
      return 'Entiendo. Por favor, dime tu nombre y el motivo de tu consulta. Notificaré de inmediato a nuestro equipo de soporte para que te contacten por correo.';
    } else {
      return 'Entiendo. Por ahora soy un bot sencillo, pero puedo ayudarte a encontrar información básica. ¿Quieres que te conecte con un asesor humano?';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomSectionHeader(
              // Hasta el 2026-08-20 decia «BOT CONTACTANOS»: ni mencionaba
              // Legacy —lo que pide la directriz de identidad— ni se
              // distinguia de la seccion Contacto, que es otra cosa. Va en
              // mayusculas como el resto de encabezados.
              title: 'ASISTENTE',
              showBackButton: true,
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _ChatBubble(message: _messages[index]);
                },
              ),
            ),

            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      'Bot escribiendo...',
                      style: GoogleFonts.questrial(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            _buildQuickActions(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildActionChip('🤝 Asesoría', 'Quiero solicitar una asesoría'),
          _buildActionChip('🏢 Programas', 'Ver programas de formación'),
          _buildActionChip('👥 Contacto', 'Hablar con un asesor humano'),
          _buildActionChip('📖 Libros', 'Recomiéndame un libro'),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, String message) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: GoogleFonts.questrial(fontSize: 12, color: AppTheme.legacyBlue1),
        ),
        backgroundColor: AppTheme.legacyBlue3.withValues(alpha: 0.05),
        shape: StadiumBorder(side: BorderSide(color: AppTheme.legacyBlue3.withValues(alpha: 0.2))),
        onPressed: () {
          _messageController.text = message;
          _sendMessage();
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje...',
                hintStyle: GoogleFonts.questrial(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                fillColor: const Color(0xFFF5F5F5),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.legacyBlue2,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final TimeOfDay time;

  Message({required this.text, required this.isUser, required this.time});
}

class _ChatBubble extends StatelessWidget {
  final Message message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppTheme.legacyBlue3
              : const Color(0xFFF5F7F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 0),
            bottomRight: Radius.circular(message.isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HtmlWidget(
              // Aquí se pinta también lo que escribe la propia persona, así que
              // sin sanear se puede inyectar HTML en su propia conversación.
              sanitizarHtml(message.text),
              textStyle: TextStyle(
                fontFamily: GoogleFonts.questrial().fontFamily,
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
              onTapUrl: (url) async {
                if (url.startsWith('internal:')) {
                  final path = url.replaceFirst('internal:', '');
                  context.push(path);
                  return true;
                }
                return false;
              },
            ),
            const SizedBox(height: 4),
            Text(
              '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: message.isUser ? Colors.white70 : Colors.black45,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
