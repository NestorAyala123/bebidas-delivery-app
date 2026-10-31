import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/application/use_cases/get_profile_use_case.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../dtos/chat_dtos.dart';

/// Opens a conversation between identified users. Idempotent: asking again for
/// the same participants, type and order returns the existing conversation.
class CreateConversationUseCase {
  final ChatRepository repository;
  final GetProfileUseCase getProfile;
  final DateTime Function() now;

  CreateConversationUseCase(
    this.repository,
    this.getProfile, {
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Result<Conversation, Failure>> call(
    CreateConversationRequest request, {
    required IdentityContract requester,
  }) async {
    if (!hasPermission(requester.rbacRole, Permission.createConversation)) {
      return const FailureResult(
        UnauthorizedFailure('Tu rol no puede iniciar conversaciones'),
      );
    }
    final ids = request.participants.map((p) => p.userId).toList();
    if (ids.toSet().length != ids.length || ids.any((id) => id.isEmpty)) {
      return const FailureResult(
        ValidationFailure('Los participantes son inválidos o están repetidos'),
      );
    }
    if (ids.length < 2) {
      return const FailureResult(
        ValidationFailure('Una conversación requiere al menos dos personas'),
      );
    }
    if (!ids.contains(requester.id)) {
      return const FailureResult(
        UnauthorizedFailure('No puedes crear conversaciones ajenas'),
      );
    }

    // Roles come from the identity module, never from the request.
    final joinedAt = now();
    final verified = <ConversationParticipant>[];
    for (final id in ids) {
      final profile = await getProfile(id, requester: requester);
      final identity = profile.dataOrNull;
      if (identity == null) {
        return FailureResult(
          profile.failureOrNull ?? const NotFoundFailure('Usuario no existe'),
        );
      }
      verified.add(
        ConversationParticipant(
          userId: id,
          role: identity.rbacRole.value,
          joinedAt: joinedAt,
        ),
      );
    }

    final existing = await repository.getConversationsForUser(requester.id);
    final found = existing.dataOrNull?.where(
      (c) =>
          c.type == request.type &&
          c.orderId == request.orderId &&
          c.participants.length == ids.length &&
          ids.every(c.hasParticipant),
    );
    if (found != null && found.isNotEmpty) return Success(found.first);

    return repository.createConversation(
      type: request.type,
      participants: verified,
      orderId: request.orderId,
    );
  }
}
