import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

/// Marks a conversation as read by the requester. Only participants can.
class MarkConversationReadUseCase {
  final ChatRepository repository;
  final DateTime Function() now;

  MarkConversationReadUseCase(this.repository, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  Future<Result<void, Failure>> call(
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
    // Read up to the newest message, so a clock skew never hides it again.
    final messages = (await repository.getMessages(conversationId)).dataOrNull;
    var readAt = now();
    if (messages != null && messages.isNotEmpty) {
      final newest = messages.last.sentAt;
      if (newest.isAfter(readAt)) readAt = newest;
    }
    return repository.markAsRead(
      conversationId: conversationId,
      userId: requester.id,
      readAt: readAt,
    );
  }
}
