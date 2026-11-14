import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../repositories/chat_repository.dart';

/// Marca como leídos los mensajes pendientes de una conversación.
class MarcarConversacionLeidaUseCase {
  final ChatRepository _repository;

  const MarcarConversacionLeidaUseCase(this._repository);

  Future<Result<void, Failure>> call({
    required String conversationId,
    required String userId,
  }) async {
    if (conversationId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('La conversación es obligatoria'),
      );
    }

    if (userId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El usuario es obligatorio'),
      );
    }

    return _repository.markConversationAsRead(
      conversationId: conversationId,
      userId: userId,
    );
  }
}
