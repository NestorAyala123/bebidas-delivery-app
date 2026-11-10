import '../entities/chat_message.dart';

/// Messages [userId] has not read yet: sent by someone else after [lastReadAt].
List<ChatMessage> unreadMessagesFor({
  required List<ChatMessage> messages,
  required String userId,
  required DateTime? lastReadAt,
}) => messages
    .where(
      (m) =>
          m.senderId != userId &&
          (lastReadAt == null || m.sentAt.isAfter(lastReadAt)),
    )
    .toList();
