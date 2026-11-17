import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';
import '../entities/chat_notification.dart';
import '../entities/conversation.dart';

/// Contrato de persistencia y observación del chat.
///
/// Soporta tanto el modelo canónico de conversaciones por sesión y participantes
/// como la observación en tiempo real y notificaciones de la app.
abstract class ChatRepository {
  Future<Result<Conversation, Failure>> createConversation({
    required ConversationType type,
    required List<ConversationParticipant> participants,
    String? orderId,
    String? subjectId,
    String? subjectTitle,
  });
  Future<Result<Conversation, Failure>> getConversation(String conversationId);
  Future<Result<List<Conversation>, Failure>> getConversationsForUser(
    String userId,
  );
  Future<Result<void, Failure>> sendMessage(ChatMessage message);

  Stream<List<ChatMessage>> getMessagesStream(String conversationId);

  /// Current messages of a conversation, oldest first.
  Future<Result<List<ChatMessage>, Failure>> getMessages(String conversationId);

  /// Records that [userId] has read [conversationId] up to [readAt].
  Future<Result<void, Failure>> markAsRead({
    required String conversationId,
    required String userId,
    required DateTime readAt,
  });

  /// When [userId] last read [conversationId], or `null` if never.
  Future<Result<DateTime?, Failure>> lastReadAt({
    required String conversationId,
    required String userId,
  });

  /// Emits whenever any message is sent or any conversation is read.
  Stream<void> get changes;

  /// Conversaciones del usuario ordenadas por último mensaje.
  Stream<List<ChatConversation>> getConversationsStream(String userId);

  /// Devuelve la conversación existente o la registra si es nueva.
  Future<Result<ChatConversation, Failure>> ensureConversation(
    ChatConversation conversation,
  );

  Future<Result<void, Failure>> markConversationAsRead({
    required String conversationId,
    required String userId,
  });

  /// Avisos en la app generados por mensajes entrantes.
  Stream<ChatNotification> get notificationsStream;
}
