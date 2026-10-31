import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../dtos/chat_dtos.dart';

class SendMessageUseCase {
  static const int maxLength = 1000;

  final ChatRepository repository;
  final DateTime Function() now;

  SendMessageUseCase(this.repository, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  Future<Result<ChatMessage, Failure>> call(
    SendMessageRequest request, {
    required IdentityContract requester,
  }) async {
    if (!hasPermission(requester.rbacRole, Permission.sendMessage)) {
      return const FailureResult(
        UnauthorizedFailure('Tu rol no puede enviar mensajes'),
      );
    }
    if (request.senderId != requester.id) {
      return const FailureResult(
        UnauthorizedFailure('No puedes enviar mensajes en nombre de otro'),
      );
    }
    final text = request.text.trim();
    if (text.isEmpty) {
      return const FailureResult(
        ValidationFailure('El mensaje no puede estar vacío'),
      );
    }
    if (text.length > maxLength) {
      return const FailureResult(
        ValidationFailure('El mensaje no puede superar $maxLength caracteres'),
      );
    }
    if (request.type != 'text') {
      return const FailureResult(
        ValidationFailure('Por ahora solo se admiten mensajes de texto'),
      );
    }

    final conversation = await repository.getConversation(
      request.conversationId,
    );
    final denied = _ensureParticipant(conversation.dataOrNull, requester.id);
    if (denied != null) return FailureResult(denied);

    final sentAt = now();
    final message = ChatMessage(
      id: 'msg-${sentAt.microsecondsSinceEpoch}',
      conversationId: request.conversationId,
      senderId: requester.id,
      text: text,
      sentAt: sentAt,
    );
    final saved = await repository.sendMessage(message);
    return saved.fold(
      onSuccess: (_) => Success(message),
      onFailure: FailureResult.new,
    );
  }

  Failure? _ensureParticipant(Conversation? conversation, String userId) {
    // A missing conversation and a foreign one look the same to the caller.
    if (conversation == null || !conversation.hasParticipant(userId)) {
      return const UnauthorizedFailure('No participas en esta conversación');
    }
    return null;
  }
}
