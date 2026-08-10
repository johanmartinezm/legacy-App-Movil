import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../../data/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  ChatService _chatService;
  WebSocketChannel? _channel;
  List<ChatConnection> _connections = [];
  List<UserModel> _members = [];
  Map<String, List<ChatMessage>> _messages = {}; // connectionId -> messages
  bool _isLoading = false;

  ChatProvider(this._chatService);

  void updateToken(String token) {
    if (token.isEmpty) {
      _channel?.sink.close();
      _channel = null;
      _connections = [];
      _messages = {};
      notifyListeners();
      return;
    }

    if (_chatService.token != token) {
      _chatService = ChatService(token);
      // Reconnect and reload when token changes
      loadConnections();
      connectWebSocket();
    }
  }

  List<ChatConnection> get connections => _connections;

  /// Id de la otra persona en una conversación, visto desde [myId].
  ///
  /// La pantalla de chat solo recibe el id de la conversación y el título, pero
  /// para reportar o bloquear hace falta saber a quién. Devuelve null si las
  /// conexiones aún no se han cargado, y en ese caso la pantalla no ofrece esas
  /// acciones en vez de arriesgarse a actuar sobre quien no es.
  String? otherUserIdOf(String connectionId, String myId) {
    for (final c in _connections) {
      if (c.id == connectionId) {
        return c.requesterId == myId ? c.receiverId : c.requesterId;
      }
    }
    return null;
  }
  List<UserModel> get members => _members;
  bool get isLoading => _isLoading;

  int get totalUnreadCount {
    final count = _connections.fold(0, (sum, conn) => sum + conn.unreadCount);
    debugPrint('ChatProvider: totalUnreadCount = $count');
    return count;
  }

  List<ChatMessage> getMessages(String connectionId) =>
      _messages[connectionId] ?? [];

  Future<void> loadConnections() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _chatService.listConnections();
      _connections = data.map((e) => ChatConnection.fromJson(e)).toList();
      debugPrint('ChatProvider: Loaded ${_connections.length} connections');
      for (var c in _connections) {
        debugPrint('Conn ${c.id}: Unread ${c.unreadCount}');
      }
    } catch (e) {
      debugPrint('Error loading connections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMembers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _chatService.fetchMembers();
      _members = data.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading members: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory(String connectionId) async {
    try {
      final data = await _chatService.getHistory(connectionId);
      _messages[connectionId] = data
          .map((e) => ChatMessage.fromJson(e))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  void connectWebSocket() {
    if (_channel != null) return;
    _channel = _chatService.connectToWs();
    if (_channel == null) return;
    _channel!.stream.listen(
      (message) {
        debugPrint('ChatProvider: Received WS message: $message');
        final data = json.decode(message);
        if (data['type'] == 'message') {
          final chatMsg = ChatMessage.fromJson(data);
          _addMessage(chatMsg);
          // Re-load connections to update unread counts in the UI (total badge)
          loadConnections();
        }
      },
      onDone: () {
        _channel = null;
      },
      onError: (e) {
        debugPrint('WebSocket error: $e');
        _channel = null;
      },
    );
  }

  void _addMessage(ChatMessage msg) {
    if (_messages[msg.connectionId] == null) {
      _messages[msg.connectionId] = [];
    }

    // De-duplicate: check if message ID already exists
    final alreadyExists = _messages[msg.connectionId]!.any(
      (m) => m.id == msg.id,
    );
    if (!alreadyExists) {
      _messages[msg.connectionId]!.insert(0, msg);
      notifyListeners();
    }
  }

  Future<void> sendMessage(String connectionId, String content) async {
    try {
      // 1. Send via REST to ensure persistence
      final msgData = await _chatService.sendMessage(connectionId, content);
      final chatMsg = ChatMessage.fromJson(msgData);

      // 2. Add to local list immediately for UI responsiveness
      _addMessage(chatMsg);

      // 3. Notify via WebSocket for real-time (optional if server already broadcasts)
      if (_channel != null) {
        final data = json.encode({
          'type':
              'message_update', // Use a different type to avoid double-processing if server reflects
          'connection_id': connectionId,
          'content': content,
        });
        _channel!.sink.add(data);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> sendInvite(String userId) async {
    await _chatService.sendInvite(userId);
    await loadConnections();
  }

  Future<void> acceptInvite(String connectionId) async {
    await _chatService.acceptInvite(connectionId);
    await loadConnections();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
