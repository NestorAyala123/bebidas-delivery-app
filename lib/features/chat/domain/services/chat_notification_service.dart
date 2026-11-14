import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';
import '../entities/chat_notification.dart';

/// Reglas puras para decidir cuándo un mensaje debe generar un aviso en la app.
class ChatNotificationService {
  const ChatNotificationService();

  /// Devuelve `null` cuando el mensaje lo envió el propio usuario.
  ChatNotification? buildForIncomingMessage({
    required ChatConversation conversation,
    required ChatMessage message,
    required String currentUserId,
  }) {
    if (message.senderId == currentUserId) {
      return null;
    }

    final preview = message.text.trim();
    if (preview.isEmpty) {
      return null;
    }

    return ChatNotification(
      id: 'notif-${message.id}',
      conversationId: conversation.id,
      title: 'Nuevo mensaje de ${conversation.counterpartName}',
      body: preview.length > 80 ? '${preview.substring(0, 77)}...' : preview,
      createdAt: message.sentAt,
    );
  }
}
