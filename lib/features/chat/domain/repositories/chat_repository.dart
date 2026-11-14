import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';
import '../entities/chat_notification.dart';

/// Contrato de persistencia y observación del chat.
///
/// Dominio puro: sin Firebase, Flutter ni HTTP. La implementación en memoria
/// se usa para la demostración y las pruebas; puede sustituirse por Firestore
/// sin cambiar casos de uso ni controladores.
abstract class ChatRepository {
  Future<Result<void, Failure>> sendMessage(ChatMessage message);

  Stream<List<ChatMessage>> getMessagesStream(String conversationId);

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
