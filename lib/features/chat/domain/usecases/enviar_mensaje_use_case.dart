import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Valida y persiste un mensaje de texto.
///
/// Reglas:
/// - Conversación y remitente obligatorios.
/// - El texto no puede estar vacío ni superar 500 caracteres.
class EnviarMensajeUseCase {
  final ChatRepository _repository;

  const EnviarMensajeUseCase(this._repository);

  Future<Result<ChatMessage, Failure>> call({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    DateTime? sentAt,
  }) async {
    if (conversationId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('La conversación es obligatoria'),
      );
    }

    if (senderId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El remitente del mensaje es obligatorio'),
      );
    }

    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return const FailureResult(
        ValidationFailure('El mensaje no puede estar vacío'),
      );
    }

    if (cleanText.length > 500) {
      return const FailureResult(
        ValidationFailure('El mensaje no puede superar los 500 caracteres'),
      );
    }

    final timestamp = sentAt ?? DateTime.now();
    final message = ChatMessage(
      id: 'msg-${timestamp.microsecondsSinceEpoch}',
      conversationId: conversationId.trim(),
      senderId: senderId.trim(),
      senderName: senderName.trim(),
      text: cleanText,
      sentAt: timestamp,
    );

    final saved = await _repository.sendMessage(message);
    return saved.fold(
      onSuccess: (_) => Success(message),
      onFailure: (failure) => FailureResult(failure),
    );
  }
}
