import '../../../core/di/service_locator.dart';
import '../../event_services/domain/repositories/ficha_servicio_repository.dart';
import '../../stores/domain/repositories/store_repository.dart';
import '../../users/application/use_cases/get_profile_use_case.dart';
import '../application/use_cases/create_conversation_use_case.dart';
import '../application/use_cases/list_conversations_use_case.dart';
import '../application/use_cases/open_inquiry_chat_use_case.dart';
import '../application/use_cases/send_message_use_case.dart';
import '../application/use_cases/watch_messages_use_case.dart';
import '../domain/repositories/chat_counterpart_directory.dart';
import '../domain/repositories/chat_repository.dart';
import '../infrastructure/catalog_chat_counterpart_directory.dart';
import '../infrastructure/in_memory_chat_repository.dart';

class ChatDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (locator.isRegistered<ChatRepository>()) return;
    locator.registerLazySingleton<ChatRepository>(InMemoryChatRepository.new);
    // Resolved on first use, so StoresProductsDi / EventServicesDi may be
    // registered before or after this module.
    locator.registerLazySingleton<ChatCounterpartDirectory>(
      () => CatalogChatCounterpartDirectory(
        stores: locator.get<StoreRepository>(),
        services: locator.get<FichaServicioRepository>(),
        demoLinks: DemoChatLinks.all,
      ),
    );
    locator.registerFactory<CreateConversationUseCase>(
      () => CreateConversationUseCase(
        locator.get<ChatRepository>(),
        locator.get<GetProfileUseCase>(),
      ),
    );
    locator.registerFactory<OpenInquiryChatUseCase>(
      () => OpenInquiryChatUseCase(
        locator.get<CreateConversationUseCase>(),
        locator.get<ChatCounterpartDirectory>(),
      ),
    );
    locator.registerFactory<ListConversationsUseCase>(
      () => ListConversationsUseCase(
        locator.get<ChatRepository>(),
        locator.get<GetProfileUseCase>(),
      ),
    );
    locator.registerFactory<SendMessageUseCase>(
      () => SendMessageUseCase(locator.get<ChatRepository>()),
    );
    locator.registerFactory<WatchMessagesUseCase>(
      () => WatchMessagesUseCase(locator.get<ChatRepository>()),
    );
  }
}
