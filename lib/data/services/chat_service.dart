import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_constants.dart';

class ChatService {
  final String token;

  ChatService(this.token);

  Future<void> sendInvite(String receiverId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/chat/connect/$receiverId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 201) {
      throw Exception(response.body);
    }
  }

  Future<void> acceptInvite(String connectionId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/chat/accept/$connectionId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  Future<List<dynamic>> listConnections() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/chat/connections'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load connections');
  }

  Future<Map<String, dynamic>> sendMessage(
    String connectionId,
    String content,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/chat/message'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'connection_id': connectionId, 'content': content}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to send message: ${response.body}');
  }

  Future<List<dynamic>> getHistory(String connectionId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/chat/history/$connectionId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load history');
  }

  Future<List<dynamic>> fetchMembers() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/chat/members'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load members');
  }

  WebSocketChannel connectToWs() {
    // Convert http/https to ws/wss
    final wsUrl = ApiConstants.baseUrl.replaceFirst('http', 'ws');
    return WebSocketChannel.connect(
      Uri.parse('$wsUrl/api/chat/ws?token=$token'),
    );
  }
}
