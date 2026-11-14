import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/chat_conversation.dart';
import 'package:bebidas_delivery_app/features/chat/domain/entities/chat_message.dart';
import 'package:bebidas_delivery_app/features/chat/domain/services/chat_notification_service.dart';

void main() {
  const service = ChatNotificationService();
  final now = DateTime(2026, 11, 15, 10);

  ChatConversation conversation() => ChatConversation(
        id: 'conv-1',
        customerId: 'customer-demo',
        counterpartId: 'store-001',
        counterpartName: 'Licorera El Barril',
        role: ChatPeerRole.store,
        updatedAt: now,
      );

  group('ChatNotificationService', () {
    test('genera aviso cuando el mensaje viene del interlocutor', () {
      final notification = service.buildForIncomingMessage(
        conversation: conversation(),
        message: ChatMessage(
          id: 'msg-1',
          conversationId: 'conv-1',
          senderId: 'store-001',
          senderName: 'Licorera El Barril',
          text: 'Tu pedido está listo',
          sentAt: now,
        ),
        currentUserId: 'customer-demo',
      );

      expect(notification, isNotNull);
      expect(notification!.conversationId, 'conv-1');
      expect(notification.title, contains('Licorera El Barril'));
      expect(notification.body, 'Tu pedido está listo');
    });

    test('no genera aviso para mensajes propios', () {
      final notification = service.buildForIncomingMessage(
        conversation: conversation(),
        message: ChatMessage(
          id: 'msg-2',
          conversationId: 'conv-1',
          senderId: 'customer-demo',
          text: 'Gracias',
          sentAt: now,
        ),
        currentUserId: 'customer-demo',
      );

      expect(notification, isNull);
    });

    test('recorta avisos largos a 80 caracteres', () {
      final notification = service.buildForIncomingMessage(
        conversation: conversation(),
        message: ChatMessage(
          id: 'msg-3',
          conversationId: 'conv-1',
          senderId: 'store-001',
          text: 'x' * 120,
          sentAt: now,
        ),
        currentUserId: 'customer-demo',
      );

      expect(notification!.body.length, 80);
      expect(notification.body.endsWith('...'), isTrue);
    });
  });
}
