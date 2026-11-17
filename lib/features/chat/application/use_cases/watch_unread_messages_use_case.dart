import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/unread_messages.dart';

/// Unread messages of one user across their conversations.
class UnreadMessages {
  final int total;

  /// The most recent unread message, for the in-app notice.
  final ChatMessage? latest;

  const UnreadMessages({required this.total, this.latest});

  static const none = UnreadMessages(total: 0);
}

/// Live count of the requester's unread messages (in-app notice and badges).
///
/// It only looks at conversations the requester participates in, so nobody is
/// notified about messages of other people's conversations.
class WatchUnreadMessagesUseCase {
  final ChatRepository repository;

  const WatchUnreadMessagesUseCase(this.repository);

  Result<Stream<UnreadMessages>, Failure> call({
    required IdentityContract requester,
  }) {
    if (!hasPermission(requester.rbacRole, Permission.readConversation)) {
      return const FailureResult(
        UnauthorizedFailure('Tu rol no puede leer conversaciones'),
      );
    }
    return Success(_watch(requester.id));
  }

  Stream<UnreadMessages> _watch(String userId) {
    late final StreamController<UnreadMessages> controller;
    StreamSubscription<void>? changes;
    // Recomputations run one after another so values arrive in order.
    var pending = Future<void>.value();
    void refresh() {
      pending = pending.then((_) async {
        final unread = await _compute(userId);
        if (!controller.isClosed) controller.add(unread);
      });
    }

    controller = StreamController<UnreadMessages>(
      onListen: () {
        changes = repository.changes.listen((_) => refresh());
        refresh();
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  Future<UnreadMessages> _compute(String userId) async {
    final conversations =
        (await repository.getConversationsForUser(userId)).dataOrNull ??
        const [];
    var total = 0;
    ChatMessage? latest;
    for (final conversation in conversations) {
      final messages =
          (await repository.getMessages(conversation.id)).dataOrNull ??
          const <ChatMessage>[];
      final lastRead = (await repository.lastReadAt(
        conversationId: conversation.id,
        userId: userId,
      )).dataOrNull;
      final unread = unreadMessagesFor(
        messages: messages,
        userId: userId,
        lastReadAt: lastRead,
      );
      total += unread.length;
      for (final message in unread) {
        if (latest == null || message.sentAt.isAfter(latest.sentAt)) {
          latest = message;
        }
      }
    }
    return UnreadMessages(total: total, latest: latest);
  }
}
