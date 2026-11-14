/// Aviso en la app de un mensaje nuevo recibido.
///
/// Permite mostrar el banner/insignia dentro de la aplicación sin depender
/// de notificaciones push del sistema operativo.
class ChatNotification {
  final String id;
  final String conversationId;
  final String title;
  final String body;
  final DateTime createdAt;

  const ChatNotification({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
