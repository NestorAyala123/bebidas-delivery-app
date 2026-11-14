import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/chat_message.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/chat_notification.dart';
import 'package:bebidas_delivery_app/features/chat/infrastructure/repositories/in_memory_chat_repository.dart';

void main() {
  group('InMemoryChatRepository', () {
    late InMemoryChatRepository repository;

    setUp(() {
      repository = InMemoryChatRepository();
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('entrega las conversaciones del cliente con no leídos', () async {
      final conversations = await repository
          .getConversationsStream('customer-demo')
          .first;

      expect(conversations, isNotEmpty);
      expect(
        conversations.where((c) => c.hasUnreadMessages),
        isNotEmpty,
      );
      expect(
        conversations.map((c) => c.role).toSet(),
        containsAll([ChatPeerRole.store, ChatPeerRole.eventProvider]),
      );
    });

    test('enviar mensaje propio actualiza el último mensaje sin no leídos',
        () async {
      final conversation =
          (await repository.getConversationsStream('customer-demo').first)
              .firstWhere((c) => c.id == 'conv-store-001');

      final sent = await repository.sendMessage(
        ChatMessage(
          id: 'msg-new',
          conversationId: conversation.id,
          senderId: 'customer-demo',
          senderName: 'Cliente',
          text: '¿Me confirman la hora de entrega?',
          sentAt: DateTime.now(),
        ),
      );

      expect(sent.isSuccess, isTrue);

      final updated = (await repository
              .getConversationsStream('customer-demo')
              .first)
          .firstWhere((c) => c.id == conversation.id);
      expect(updated.lastMessage?.text, contains('hora de entrega'));
      expect(updated.unreadCount, conversation.unreadCount);
    });

    test('mensaje entrante incrementa no leídos y emite aviso', () async {
      final notifications = <ChatNotification>[];
      final subscription = repository.notificationsStream.listen(
        notifications.add,
      );

      await repository.simulateIncomingMessage(
        conversationId: 'conv-prov-001',
        text: 'La cotización está lista',
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final updated =
          (await repository.getConversationsStream('customer-demo').first)
              .firstWhere((c) => c.id == 'conv-prov-001');

      expect(updated.unreadCount, greaterThan(1));
      expect(notifications, isNotEmpty);
      expect(notifications.last.body, 'La cotización está lista');

      await subscription.cancel();
    });

    test('marcar como leída deja el contador en cero', () async {
      await repository.markConversationAsRead(
        conversationId: 'conv-store-001',
        userId: 'customer-demo',
      );

      final updated =
          (await repository.getConversationsStream('customer-demo').first)
              .firstWhere((c) => c.id == 'conv-store-001');

      expect(updated.unreadCount, 0);
      expect(updated.hasUnreadMessages, isFalse);
    });

    test('ensureConversation reutiliza el hilo del mismo contexto', () async {
      final first = await repository.ensureConversation(
        ChatConversation(
          id: 'conv-new',
          customerId: 'customer-demo',
          counterpartId: 'prov-999',
          counterpartName: 'DJ Demo',
          role: ChatPeerRole.eventProvider,
          contextId: 'svc-999',
          updatedAt: DateTime.now(),
        ),
      );

      final second = await repository.ensureConversation(
        ChatConversation(
          id: 'conv-other-id',
          customerId: 'customer-demo',
          counterpartId: 'prov-999',
          counterpartName: 'DJ Demo',
          role: ChatPeerRole.eventProvider,
          contextId: 'svc-999',
          updatedAt: DateTime.now(),
        ),
      );

      expect(first.dataOrNull?.id, 'conv-new');
      expect(second.dataOrNull?.id, 'conv-new');
    });

    test('sendMessage falla si la conversación no existe', () async {
      final result = await repository.sendMessage(
        ChatMessage(
          id: 'msg-x',
          conversationId: 'no-existe',
          senderId: 'customer-demo',
          text: 'Hola',
          sentAt: DateTime.now(),
        ),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
