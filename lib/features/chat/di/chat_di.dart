import '../../../../core/di/service_locator.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/crear_conversacion_use_case.dart';
import '../domain/usecases/enviar_mensaje_use_case.dart';
import '../domain/usecases/marcar_conversacion_leida_use_case.dart';
import '../domain/usecases/obtener_conversaciones_use_case.dart';
import '../infrastructure/repositories/in_memory_chat_repository.dart';
import '../presentation/chat_controller_factory.dart';
import '../presentation/controllers/chat_controller.dart';

/// Módulo de Inyección de Dependencias para Chat (Nibia).
class ChatDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<ChatRepository>()) {
      locator.registerLazySingleton<ChatRepository>(
        () => InMemoryChatRepository(),
      );
    }

    if (!locator.isRegistered<ObtenerConversacionesUseCase>()) {
      locator.registerFactory<ObtenerConversacionesUseCase>(
        () => ObtenerConversacionesUseCase(locator.get<ChatRepository>()),
      );
    }

    if (!locator.isRegistered<EnviarMensajeUseCase>()) {
      locator.registerFactory<EnviarMensajeUseCase>(
        () => EnviarMensajeUseCase(locator.get<ChatRepository>()),
      );
    }

    if (!locator.isRegistered<MarcarConversacionLeidaUseCase>()) {
      locator.registerFactory<MarcarConversacionLeidaUseCase>(
        () => MarcarConversacionLeidaUseCase(locator.get<ChatRepository>()),
      );
    }

    if (!locator.isRegistered<CrearConversacionUseCase>()) {
      locator.registerFactory<CrearConversacionUseCase>(
        () => CrearConversacionUseCase(locator.get<ChatRepository>()),
      );
    }

    if (!locator.isRegistered<ChatController>()) {
      locator.registerFactory<ChatController>(
        () => buildChatController(repository: locator.get<ChatRepository>()),
      );
    }
  }
}
