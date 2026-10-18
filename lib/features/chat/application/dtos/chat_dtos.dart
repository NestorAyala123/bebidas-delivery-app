import '../../domain/entities/conversation.dart';

class CreateConversationRequest {
  final ConversationType type;
  final List<ConversationParticipant> participants;
  final String? orderId;

  const CreateConversationRequest({
    required this.type,
    required this.participants,
    this.orderId,
  });
}

class AddParticipantRequest {
  final String userId;
  final String role;

  const AddParticipantRequest({required this.userId, required this.role});
}

class SendMessageRequest {
  final String conversationId;
  final String senderId;
  final String text;
  final String type;

  const SendMessageRequest({
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.type = 'text',
  });
}
