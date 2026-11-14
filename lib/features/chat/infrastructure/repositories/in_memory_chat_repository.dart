import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_notification.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/chat_notification_service.dart';

/// Implementación en memoria del chat para demostraciones y pruebas.
///
/// Mantiene conversaciones de ejemplo con un comercio y un proveedor de
/// eventos, simula mensajes entrantes y expone streams que la UI observa.
class InMemoryChatRepository implements ChatRepository {
  final ChatNotificationService _notificationService;
  final List<ChatConversation> _conversations;
  final Map<String, List<ChatMessage>> _messages;

  final StreamController<void> _changes = StreamController<void>.broadcast();
  final StreamController<ChatNotification> _notifications =
      StreamController<ChatNotification>.broadcast();

  InMemoryChatRepository({
    ChatNotificationService? notificationService,
    List<ChatConversation>? initialConversations,
    Map<String, List<ChatMessage>>? initialMessages,
  })  : _notificationService =
            notificationService ?? const ChatNotificationService(),
        _conversations = initialConversations ?? _seedConversations(),
        _messages = initialMessages ?? _seedMessages();

  static DateTime get _baseDate => DateTime(2026, 11, 15, 9, 30);

  static List<ChatConversation> _seedConversations() {
    final base = _baseDate;
    return [
      ChatConversation(
        id: 'conv-store-001',
        customerId: 'customer-demo',
        counterpartId: 'store-001',
        counterpartName: 'Licorera El Barril',
        role: ChatPeerRole.store,
        contextId: 'store-001',
        contextLabel: 'Pedido en Av. Flavio Reyes y Calle 24',
        lastMessage: ChatMessage(
          id: 'msg-seed-store-2',
          conversationId: 'conv-store-001',
          senderId: 'store-001',
          senderName: 'Licorera El Barril',
          text: 'Tu pedido ya está confirmado. ¿Deseas delivery externo?',
          sentAt: base.add(const Duration(minutes: 4)),
        ),
        unreadCount: 1,
        updatedAt: base.add(const Duration(minutes: 4)),
      ),
      ChatConversation(
        id: 'conv-prov-001',
        customerId: 'customer-demo',
        counterpartId: 'prov-001',
        counterpartName: 'Bartender Profesional para Fiestas',
        role: ChatPeerRole.eventProvider,
        contextId: 'svc-001',
        contextLabel: 'Consulta para evento del 20/12/2026',
        lastMessage: ChatMessage(
          id: 'msg-seed-prov-2',
          conversationId: 'conv-prov-001',
          senderId: 'prov-001',
          senderName: 'Bartender Profesional para Fiestas',
          text: 'Hola, recibimos tu consulta. Podemos cotizar 2 bármanes.',
          sentAt: base.add(const Duration(minutes: 1)),
        ),
        unreadCount: 1,
        updatedAt: base.add(const Duration(minutes: 1)),
      ),
      ChatConversation(
        id: 'conv-driver-701',
        customerId: 'customer-demo',
        counterpartId: 'drv-701',
        counterpartName: 'Carlos Mendoza',
        role: ChatPeerRole.driver,
        contextId: 'req-demo-01',
        contextLabel: 'Entrega hacia Av. Malecón',
        updatedAt: base.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  static Map<String, List<ChatMessage>> _seedMessages() {
    final base = _baseDate;
    return {
      'conv-store-001': [
        ChatMessage(
          id: 'msg-seed-store-1',
          conversationId: 'conv-store-001',
          senderId: 'customer-demo',
          senderName: 'Cliente',
          text: 'Buenas tardes, ¿tienen packs de cerveza artesanal?',
          sentAt: base,
          isRead: true,
        ),
        ChatMessage(
          id: 'msg-seed-store-2',
          conversationId: 'conv-store-001',
          senderId: 'store-001',
          senderName: 'Licorera El Barril',
          text: 'Tu pedido ya está confirmado. ¿Deseas delivery externo?',
          sentAt: base.add(const Duration(minutes: 4)),
        ),
      ],
      'conv-prov-001': [
        ChatMessage(
          id: 'msg-seed-prov-1',
          conversationId: 'conv-prov-001',
          senderId: 'customer-demo',
          senderName: 'Cliente',
          text: 'Hola, necesito un bartender para 80 invitados.',
          sentAt: base.subtract(const Duration(minutes: 20)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg-seed-prov-2',
          conversationId: 'conv-prov-001',
          senderId: 'prov-001',
          senderName: 'Bartender Profesional para Fiestas',
          text: 'Hola, recibimos tu consulta. Podemos cotizar 2 bármanes.',
          sentAt: base.add(const Duration(minutes: 1)),
        ),
      ],
      'conv-driver-701': const [],
    };
  }

  /// Conversaciones del usuario ordenadas por actividad reciente.
  List<ChatConversation> _conversationsFor(String userId) {
    final found = _conversations
        .where((c) => c.customerId == userId || c.counterpartId == userId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return found;
  }

  List<ChatMessage> _messagesOf(String conversationId) {
    final messages = List<ChatMessage>.from(
      _messages[conversationId] ?? const <ChatMessage>[],
    )..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  ChatConversation? _findConversation(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  @override
  Future<Result<void, Failure>> sendMessage(ChatMessage message) async {
    final conversation = _findConversation(message.conversationId);
    if (conversation == null) {
      return const FailureResult(
        NotFoundFailure('La conversación indicada no existe'),
      );
    }

    _messages.putIfAbsent(message.conversationId, () => []).add(message);

    final isIncoming =
        message.senderId != conversation.customerId &&
        message.senderId != 'customer-demo';

    _replaceConversation(
      conversation.copyWith(
        lastMessage: message,
        unreadCount: isIncoming
            ? conversation.unreadCount + 1
            : conversation.unreadCount,
        updatedAt: message.sentAt,
      ),
    );

    if (isIncoming) {
      final notification = _notificationService.buildForIncomingMessage(
        conversation: conversation,
        message: message,
        currentUserId: conversation.customerId,
      );
      if (notification != null) {
        _notifications.add(notification);
      }
    }

    _changes.add(null);
    return const Success(null);
  }

  void _replaceConversation(ChatConversation updated) {
    final index = _conversations.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _conversations[index] = updated;
    } else {
      _conversations.add(updated);
    }
  }

  @override
  Stream<List<ChatMessage>> getMessagesStream(String conversationId) async* {
    yield _messagesOf(conversationId);
    yield* _changes.stream.map((_) => _messagesOf(conversationId));
  }

  @override
  Stream<List<ChatConversation>> getConversationsStream(String userId) async* {
    yield _conversationsFor(userId);
    yield* _changes.stream.map((_) => _conversationsFor(userId));
  }

  @override
  Future<Result<ChatConversation, Failure>> ensureConversation(
    ChatConversation conversation,
  ) async {
    final existing = _conversations.where((c) {
      return c.customerId == conversation.customerId &&
          c.counterpartId == conversation.counterpartId &&
          c.contextId == conversation.contextId;
    });

    if (existing.isNotEmpty) {
      return Success(existing.first);
    }

    _replaceConversation(conversation);
    _changes.add(null);
    return Success(conversation);
  }

  @override
  Future<Result<void, Failure>> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    final conversation = _findConversation(conversationId);
    if (conversation == null) {
      return const FailureResult(
        NotFoundFailure('La conversación indicada no existe'),
      );
    }

    final messages = _messages[conversationId];
    if (messages != null) {
      for (var i = 0; i < messages.length; i++) {
        if (messages[i].senderId != userId) {
          messages[i] = messages[i].copyWith(isRead: true);
        }
      }
    }

    _replaceConversation(conversation.copyWith(unreadCount: 0));
    _changes.add(null);
    return const Success(null);
  }

  @override
  Stream<ChatNotification> get notificationsStream => _notifications.stream;

  /// Simula la llegada de un mensaje del interlocutor para demostrar el
  /// aviso dentro de la app sin depender de un backend en tiempo real.
  Future<void> simulateIncomingMessage({
    required String conversationId,
    String text = 'Perfecto, quedo atento a tu confirmación.',
  }) async {
    final conversation = _findConversation(conversationId);
    if (conversation == null) return;

    final now = DateTime.now();
    await sendMessage(
      ChatMessage(
        id: 'msg-sim-${now.microsecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: conversation.counterpartId,
        senderName: conversation.counterpartName,
        text: text,
        sentAt: now,
      ),
    );
  }

  /// Cierra los streams internos (útil en pruebas que crean varias instancias).
  Future<void> dispose() async {
    await _changes.close();
    await _notifications.close();
  }
}
