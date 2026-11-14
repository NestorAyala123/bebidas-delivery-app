import 'chat_message.dart';

/// Rol del interlocutor dentro de una conversación de la plataforma.
enum ChatPeerRole {
  store,
  eventProvider,
  driver,
  support;

  String get label => switch (this) {
    ChatPeerRole.store => 'Comercio',
    ChatPeerRole.eventProvider => 'Proveedor de eventos',
    ChatPeerRole.driver => 'Repartidor',
    ChatPeerRole.support => 'Soporte',
  };
}

/// Conversación de chat asociada a un comercio, servicio o entrega.
///
/// `contextId` permite enlazar el hilo con la entidad de origen
/// (tienda, ficha de servicio, pedido o entrega) sin acoplar módulos.
class ChatConversation {
  final String id;
  final String customerId;
  final String counterpartId;
  final String counterpartName;
  final ChatPeerRole role;
  final String? contextId;
  final String contextLabel;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    required this.customerId,
    required this.counterpartId,
    required this.counterpartName,
    required this.role,
    this.contextId,
    this.contextLabel = '',
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  bool get hasUnreadMessages => unreadCount > 0;

  ChatConversation copyWith({
    String? id,
    String? customerId,
    String? counterpartId,
    String? counterpartName,
    ChatPeerRole? role,
    String? contextId,
    String? contextLabel,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      counterpartId: counterpartId ?? this.counterpartId,
      counterpartName: counterpartName ?? this.counterpartName,
      role: role ?? this.role,
      contextId: contextId ?? this.contextId,
      contextLabel: contextLabel ?? this.contextLabel,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatConversation(id: $id, peer: $counterpartName, unread: $unreadCount)';
}
