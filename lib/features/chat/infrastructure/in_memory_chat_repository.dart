import 'dart:async';

import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/conversation.dart';
import '../domain/repositories/chat_repository.dart';

/// In-memory adapter for local development and tests. Replace with Firestore.
class InMemoryChatRepository implements ChatRepository {
  final DateTime Function() _now;
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, StreamController<List<ChatMessage>>> _changes = {};

  InMemoryChatRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  @override
  Future<Result<Conversation, Failure>> createConversation({
    required ConversationType type,
    required List<ConversationParticipant> participants,
    String? orderId,
  }) async {
    final createdAt = _now();
    final conversation = Conversation(
      id: 'cnv-${_conversations.length + 1}',
      type: type,
      participants: List.unmodifiable(participants),
      orderId: orderId,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    _conversations[conversation.id] = conversation;
    return Success(conversation);
  }

  @override
  Future<Result<Conversation, Failure>> getConversation(
    String conversationId,
  ) async {
    final conversation = _conversations[conversationId];
    if (conversation == null) {
      return const FailureResult(
        NotFoundFailure('Conversación no encontrada'),
      );
    }
    return Success(conversation);
  }

  @override
  Future<Result<List<Conversation>, Failure>> getConversationsForUser(
    String userId,
  ) async => Success(
    _conversations.values.where((c) => c.hasParticipant(userId)).toList(),
  );

  @override
  Future<Result<void, Failure>> sendMessage(ChatMessage message) async {
    final conversation = _conversations[message.conversationId];
    if (conversation == null) {
      return const FailureResult(
        NotFoundFailure('Conversación no encontrada'),
      );
    }
    _messages.putIfAbsent(message.conversationId, () => []).add(message);
    _conversations[conversation.id] = Conversation(
      id: conversation.id,
      type: conversation.type,
      participants: conversation.participants,
      orderId: conversation.orderId,
      createdAt: conversation.createdAt,
      updatedAt: message.sentAt,
    );
    _changes[message.conversationId]?.add(_snapshot(message.conversationId));
    return const Success(null);
  }

  @override
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) {
    final changes = _changes.putIfAbsent(
      conversationId,
      () => StreamController<List<ChatMessage>>.broadcast(),
    );
    late final StreamController<List<ChatMessage>> controller;
    StreamSubscription<List<ChatMessage>>? subscription;
    controller = StreamController<List<ChatMessage>>(
      onListen: () {
        controller.add(_snapshot(conversationId));
        subscription = changes.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  List<ChatMessage> _snapshot(String conversationId) =>
      List.unmodifiable(_messages[conversationId] ?? const []);
}
