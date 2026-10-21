import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

/// Messages are readable only by the participants of the conversation.
class WatchMessagesUseCase {
  final ChatRepository repository;

  const WatchMessagesUseCase(this.repository);

  Future<Result<Stream<List<ChatMessage>>, Failure>> call(
    String conversationId, {
    required IdentityContract requester,
  }) async {
    if (!hasPermission(requester.rbacRole, Permission.readConversation)) {
      return const FailureResult(
        UnauthorizedFailure('Tu rol no puede leer conversaciones'),
      );
    }
    final conversation = await repository.getConversation(conversationId);
    if (conversation.dataOrNull?.hasParticipant(requester.id) != true) {
      return const FailureResult(
        UnauthorizedFailure('No participas en esta conversación'),
      );
    }
    return Success(repository.getMessagesStream(conversationId));
  }
}
