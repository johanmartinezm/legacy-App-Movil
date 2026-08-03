import 'package:flutter_test/flutter_test.dart';
import 'package:legacy_app/domain/providers/chat_provider.dart';
import 'package:legacy_app/data/services/chat_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'chat_provider_test.mocks.dart';

@GenerateMocks([ChatService, WebSocketChannel, WebSocketSink])
void main() {
  group('ChatProvider Tests', () {
    late MockChatService mockService;
    late ChatProvider chatProvider;

    setUp(() {
      mockService = MockChatService();
      chatProvider = ChatProvider(mockService);
    });

    test('loadConnections should update connections list', () async {
      when(mockService.listConnections()).thenAnswer(
        (_) async => [
          {
            'id': 'conn1',
            'requester_id': 'user1',
            'receiver_id': 'user2',
            'status': 'ACCEPTED',
            'updated_at': '2026-02-27T10:00:00Z',
          },
        ],
      );

      await chatProvider.loadConnections();

      expect(chatProvider.connections.length, 1);
      expect(chatProvider.connections[0].id, 'conn1');
      expect(chatProvider.isLoading, false);
    });

    test('sendInvite should call service and reload connections', () async {
      when(mockService.sendInvite(any)).thenAnswer((_) async => {});
      when(mockService.listConnections()).thenAnswer((_) async => []);

      await chatProvider.sendInvite('user2');

      verify(mockService.sendInvite('user2')).called(1);
    });

    test('loadHistory should update messages map', () async {
      when(mockService.getHistory(any)).thenAnswer(
        (_) async => [
          {
            'id': 'msg1',
            'connection_id': 'conn1',
            'sender_id': 'user1',
            'content': 'hello',
            'is_read': false,
            'created_at': '2026-02-27T10:05:00Z',
          },
        ],
      );

      await chatProvider.loadHistory('conn1');

      final messages = chatProvider.getMessages('conn1');
      expect(messages.length, 1);
      expect(messages[0].content, 'hello');
    });
  });
}
