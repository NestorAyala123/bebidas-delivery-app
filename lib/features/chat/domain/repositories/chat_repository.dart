import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<Result<void, Failure>> sendMessage(ChatMessage message);
  Stream<List<ChatMessage>> getMessagesStream(String conversationId);
}
