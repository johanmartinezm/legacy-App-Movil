import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import '../../../domain/providers/chat_provider.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../widgets/custom_section_header.dart';

class IndividualChatScreen extends StatefulWidget {
  final String connectionId;
  final String chatTitle;

  const IndividualChatScreen({
    super.key,
    required this.connectionId,
    required this.chatTitle,
  });

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _emojiShowing = false;

  @override
  void initState() {
    super.initState();
    final chatProvider = context.read<ChatProvider>();
    Future.microtask(() {
      chatProvider.loadHistory(widget.connectionId);
      chatProvider.connectWebSocket();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _emojiShowing = false;
        });
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    context.read<ChatProvider>().sendMessage(
      widget.connectionId,
      _messageController.text.trim(),
    );
    _messageController.clear();
    if (_emojiShowing) {
      setState(() {
        _emojiShowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthProvider>().userID;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      body: SafeArea(
        child: Column(
          children: [
            CustomSectionHeader(
              title: widget.chatTitle.toUpperCase(),
              showBackButton: true,
            ),

            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final messages = chatProvider.getMessages(
                    widget.connectionId,
                  );

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == myId;

                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),

            _buildInputArea(),

            Offstage(
              offstage: !_emojiShowing,
              child: SizedBox(
                height: 256,
                child: emoji_picker.EmojiPicker(
                  textEditingController: _messageController,
                  config: const emoji_picker.Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: emoji_picker.EmojiViewConfig(
                      emojiSizeMax: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isOnlyEmojis(String text) {
    if (text.isEmpty) return false;
    // Regex for basic emojis
    final emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
    );
    return emojiRegex.hasMatch(text.replaceAll(' ', ''));
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.legacyBlue3 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                fontFamily: GoogleFonts.questrial().fontFamily,
                fontFamilyFallback: AppTheme.emojiFallbacks,
                color: isMe ? Colors.white : Colors.black87,
                fontSize: _isOnlyEmojis(msg.content) ? 24 : 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.createdAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
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
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _emojiShowing ? Icons.keyboard : Icons.emoji_emotions_outlined,
              color: AppTheme.legacyBlue1,
            ),
            onPressed: () {
              if (_emojiShowing) {
                _focusNode.requestFocus();
              } else {
                _focusNode.unfocus();
              }
              setState(() {
                _emojiShowing = !_emojiShowing;
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje de confianza...',
                hintStyle: GoogleFonts.questrial(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
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
            backgroundColor: AppTheme.legacyBlue1,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
