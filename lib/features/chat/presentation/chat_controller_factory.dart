import '../../../../core/di/service_locator.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/enviar_mensaje_use_case.dart';
import '../domain/usecases/marcar_conversacion_leida_use_case.dart';
import '../domain/usecases/obtener_conversaciones_use_case.dart';
import '../infrastructure/repositories/in_memory_chat_repository.dart';
import 'controllers/chat_controller.dart';

/// Construye el controlador usando el contenedor de dependencias y, si aún no
/// está registrado, una implementación en memoria para demostraciones.
ChatController buildChatController({
  ChatRepository? repository,
  String userId = 'customer-demo',
  String userName = 'Cliente',
}) {
  final ChatRepository chatRepository =
      repository ??
      (sl.isRegistered<ChatRepository>()
          ? sl.get<ChatRepository>()
          : InMemoryChatRepository());

  final inMemory = chatRepository is InMemoryChatRepository
      ? chatRepository
      : null;

  return ChatController(
    obtenerConversacionesUseCase: ObtenerConversacionesUseCase(chatRepository),
    enviarMensajeUseCase: EnviarMensajeUseCase(chatRepository),
    marcarConversacionLeidaUseCase: MarcarConversacionLeidaUseCase(
      chatRepository,
    ),
    chatRepository: chatRepository,
    userId: userId,
    userName: userName,
    simulateIncoming: inMemory == null
        ? null
        : (conversationId) =>
              inMemory.simulateIncomingMessage(conversationId: conversationId),
  );
}
