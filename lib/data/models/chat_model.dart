class ChatConnection {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final DateTime updatedAt;
  final int unreadCount;
  final Map<String, dynamic>? otherUser;

  ChatConnection({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.updatedAt,
    this.unreadCount = 0,
    this.otherUser,
  });

  factory ChatConnection.fromJson(Map<String, dynamic> json) {
    return ChatConnection(
      id: json['id'],
      requesterId: json['requester_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      updatedAt: DateTime.parse(json['updated_at']),
      unreadCount: json['unread_count'] ?? 0,
      otherUser: json['other_user'],
    );
  }
}

class ChatMessage {
  final String id;
  final String connectionId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.connectionId,
    required this.senderId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      connectionId: json['connection_id'],
      senderId: json['sender_id'],
      content: json['content'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
