import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/chat_conversation.dart';
import '../repositories/chat_repository.dart';

/// Observa las conversaciones activas del usuario.
///
/// La validación del identificador evita consultas vacías o mal formadas.
class ObtenerConversacionesUseCase {
  final ChatRepository _repository;

  const ObtenerConversacionesUseCase(this._repository);

  Result<Stream<List<ChatConversation>>, Failure> call(String userId) {
    final id = userId.trim();
    if (id.isEmpty) {
      return const FailureResult(
        ValidationFailure('El usuario de la conversación es obligatorio'),
      );
    }
    return Success(_repository.getConversationsStream(id));
  }
}
