import '../../../../core/di/service_locator.dart';
import '../../event_services/domain/repositories/ficha_servicio_repository.dart';
import '../../stores/domain/repositories/store_repository.dart';
import '../../users/application/use_cases/get_profile_use_case.dart';
import '../application/use_cases/create_conversation_use_case.dart';
import '../application/use_cases/list_conversations_use_case.dart';
import '../application/use_cases/mark_conversation_read_use_case.dart';
import '../application/use_cases/open_inquiry_chat_use_case.dart';
import '../application/use_cases/send_message_use_case.dart';
import '../application/use_cases/watch_messages_use_case.dart';
import '../application/use_cases/watch_unread_messages_use_case.dart';
import '../domain/repositories/chat_counterpart_directory.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/crear_conversacion_use_case.dart';
import '../domain/usecases/enviar_mensaje_use_case.dart';
import '../domain/usecases/marcar_conversacion_leida_use_case.dart';
import '../domain/usecases/obtener_conversaciones_use_case.dart';
import '../infrastructure/catalog_chat_counterpart_directory.dart';
import '../infrastructure/repositories/in_memory_chat_repository.dart';
import '../presentation/chat_controller_factory.dart';
import '../presentation/controllers/chat_controller.dart';

/// Módulo de Inyección de Dependencias para Chat.
class ChatDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<ChatRepository>()) {
      locator.registerLazySingleton<ChatRepository>(
        () => InMemoryChatRepository(),
      );
    }

    // Resolved on first use, so StoresProductsDi / EventServicesDi may be
    // registered before or after this module.
    if (!locator.isRegistered<ChatCounterpartDirectory>()) {
      locator.registerLazySingleton<ChatCounterpartDirectory>(
        () => CatalogChatCounterpartDirectory(
          stores: locator.get<StoreRepository>(),
          services: locator.get<FichaServicioRepository>(),
          demoLinks: DemoChatLinks.all,
        ),
      );
    }

    if (!locator.isRegistered<CreateConversationUseCase>()) {
      locator.registerFactory<CreateConversationUseCase>(
        () => CreateConversationUseCase(
          locator.get<ChatRepository>(),
          locator.get<GetProfileUseCase>(),
        ),
      );
    }

    if (!locator.isRegistered<OpenInquiryChatUseCase>()) {
      locator.registerFactory<OpenInquiryChatUseCase>(
        () => OpenInquiryChatUseCase(
          locator.get<CreateConversationUseCase>(),
          locator.get<ChatCounterpartDirectory>(),
        ),
      );
    }

    if (!locator.isRegistered<ListConversationsUseCase>()) {
      locator.registerFactory<ListConversationsUseCase>(
        () => ListConversationsUseCase(
          locator.get<ChatRepository>(),
          locator.get<GetProfileUseCase>(),
        ),
      );
    }

    if (!locator.isRegistered<SendMessageUseCase>()) {
      locator.registerFactory<SendMessageUseCase>(
        () => SendMessageUseCase(locator.get<ChatRepository>()),
      );
    }

    if (!locator.isRegistered<WatchMessagesUseCase>()) {
      locator.registerFactory<WatchMessagesUseCase>(
        () => WatchMessagesUseCase(locator.get<ChatRepository>()),
      );
    }

    if (!locator.isRegistered<MarkConversationReadUseCase>()) {
      locator.registerFactory<MarkConversationReadUseCase>(
        () => MarkConversationReadUseCase(locator.get<ChatRepository>()),
      );
    }

    if (!locator.isRegistered<WatchUnreadMessagesUseCase>()) {
      locator.registerFactory<WatchUnreadMessagesUseCase>(
        () => WatchUnreadMessagesUseCase(locator.get<ChatRepository>()),
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
