import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/application/use_cases/get_profile_use_case.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

class ConversationSummary {
  final Conversation conversation;
  final String title;

  const ConversationSummary({required this.conversation, required this.title});
}

/// Conversations of the requester, titled with the other participants' names.
class ListConversationsUseCase {
  final ChatRepository repository;
  final GetProfileUseCase getProfile;

  const ListConversationsUseCase(this.repository, this.getProfile);

  Future<Result<List<ConversationSummary>, Failure>> call({
    required IdentityContract requester,
  }) async {
    if (!hasPermission(requester.rbacRole, Permission.readConversation)) {
      return const FailureResult(
        UnauthorizedFailure('Tu rol no puede leer conversaciones'),
      );
    }
    final result = await repository.getConversationsForUser(requester.id);
    final conversations = result.dataOrNull;
    if (conversations == null) {
      return FailureResult(
        result.failureOrNull ?? const ServerFailure('No se pudo cargar'),
      );
    }
    final summaries = <ConversationSummary>[];
    for (final conversation in conversations) {
      final names = <String>[];
      for (final participant in conversation.participants) {
        if (participant.userId == requester.id) continue;
        final profile = await getProfile(
          participant.userId,
          requester: requester,
        );
        names.add(profile.dataOrNull?.displayName ?? 'Usuario');
      }
      summaries.add(
        ConversationSummary(
          conversation: conversation,
          title: names.isEmpty ? 'Conversación' : names.join(', '),
        ),
      );
    }
    summaries.sort(
      (a, b) => b.conversation.updatedAt.compareTo(a.conversation.updatedAt),
    );
    return Success(summaries);
  }
}
