import '../../../users/domain/entities/role.dart';
import '../entities/conversation.dart';

/// Decides which roles may talk to each other, per conversation type.
///
/// Pure domain rule: the use cases ask it with roles verified by the identity
/// module, never with roles sent by the client.
class ConversationPolicy {
  const ConversationPolicy._();

  /// Role pairs allowed for a [ConversationType.direct] conversation.
  static const Set<Set<Role>> _directPairs = {
    {Role.client, Role.store},
    {Role.client, Role.eventProvider},
    {Role.client, Role.driver},
    {Role.store, Role.driver},
  };

  /// Returns a reason when the conversation is not allowed, or `null`.
  static String? denialReason({
    required ConversationType type,
    required List<Role> roles,
    String? orderId,
    String? subjectId,
  }) {
    if (roles.length != 2) {
      return 'Una conversación es entre exactamente dos personas';
    }
    final pair = roles.toSet();
    switch (type) {
      case ConversationType.storeInquiry:
        if (_isEmpty(subjectId)) return 'Falta el comercio de la conversación';
        if (!_same(pair, {Role.client, Role.store})) {
          return 'Solo un cliente y un comercio pueden usar este chat';
        }
      case ConversationType.serviceInquiry:
        if (_isEmpty(subjectId)) return 'Falta el servicio de la conversación';
        if (!_same(pair, {Role.client, Role.eventProvider})) {
          return 'Solo un cliente y un proveedor de eventos pueden usar este chat';
        }
      case ConversationType.orderSupport:
        if (_isEmpty(orderId)) return 'Falta el pedido de la conversación';
        if (!_allowsDirect(pair) || pair.contains(Role.eventProvider)) {
          return 'Estos roles no pueden conversar sobre un pedido';
        }
      case ConversationType.direct:
        if (!_allowsDirect(pair)) {
          return 'Estos roles no pueden conversar entre sí';
        }
    }
    return null;
  }

  /// Whether [a] may start a direct conversation with [b].
  static bool canTalkDirectly(Role a, Role b) => _allowsDirect({a, b});

  static bool _allowsDirect(Set<Role> pair) =>
      _directPairs.any((allowed) => _same(allowed, pair));

  static bool _same(Set<Role> a, Set<Role> b) =>
      a.length == b.length && a.containsAll(b);

  static bool _isEmpty(String? value) => value == null || value.trim().isEmpty;
}
