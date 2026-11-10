/// Kinds of conversation the MVP supports.
///
/// - [direct]: two identified users that may talk (see `ConversationPolicy`).
/// - [orderSupport]: tied to an `orderId`.
/// - [storeInquiry]: a client asks a store (tied to a `storeId`).
/// - [serviceInquiry]: a client asks an event provider (tied to a `serviceId`).
enum ConversationType { direct, orderSupport, storeInquiry, serviceInquiry }

class ConversationParticipant {
  final String userId;
  final String role;
  final DateTime joinedAt;

  const ConversationParticipant({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  Map<String, Object?> toJson() => {
    'userId': userId,
    'role': role,
    'joinedAt': joinedAt.toUtc().toIso8601String(),
  };
}

class Conversation {
  final String id;
  final ConversationType type;
  final List<ConversationParticipant> participants;
  final String? orderId;

  /// The store or service the conversation is about (`storeId` / `serviceId`).
  final String? subjectId;

  /// Human label of the subject, e.g. the store name or the service title.
  final String? subjectTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.type,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.orderId,
    this.subjectId,
    this.subjectTitle,
  });

  Conversation copyWith({DateTime? updatedAt}) => Conversation(
    id: id,
    type: type,
    participants: participants,
    orderId: orderId,
    subjectId: subjectId,
    subjectTitle: subjectTitle,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

extension ConversationAccess on Conversation {
  bool hasParticipant(String userId) =>
      participants.any((participant) => participant.userId == userId);
}
