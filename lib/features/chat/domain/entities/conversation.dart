enum ConversationType { direct, orderSupport }

class ConversationParticipant {
  final String userId;
  final String role;
  final DateTime joinedAt;

  const ConversationParticipant({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  Map<String, Object> toJson() => {
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
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.type,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.orderId,
  });
}
