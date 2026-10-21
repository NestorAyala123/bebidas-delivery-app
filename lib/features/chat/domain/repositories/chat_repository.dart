import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

/// Storage port for chat. It does not authorize: use cases decide who may
/// read or write before calling it.
abstract class ChatRepository {
  Future<Result<Conversation, Failure>> createConversation({
    required ConversationType type,
    required List<ConversationParticipant> participants,
    String? orderId,
  });
  Future<Result<Conversation, Failure>> getConversation(String conversationId);
  Future<Result<List<Conversation>, Failure>> getConversationsForUser(
    String userId,
  );
  Future<Result<void, Failure>> sendMessage(ChatMessage message);
  Stream<List<ChatMessage>> getMessagesStream(String conversationId);
}
