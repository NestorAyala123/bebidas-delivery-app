import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/chat_conversation.dart';
import '../repositories/chat_repository.dart';

/// Garantiza que exista un hilo de chat antes de abrirlo desde comercio,
/// servicio de eventos o entrega.
class CrearConversacionUseCase {
  final ChatRepository _repository;

  const CrearConversacionUseCase(this._repository);

  Future<Result<ChatConversation, Failure>> call(
    ChatConversation conversation,
  ) async {
    if (conversation.customerId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El cliente de la conversación es obligatorio'),
      );
    }

    if (conversation.counterpartId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El interlocutor de la conversación es obligatorio'),
      );
    }

    if (conversation.counterpartName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El nombre del interlocutor es obligatorio'),
      );
    }

    return _repository.ensureConversation(conversation);
  }
}
