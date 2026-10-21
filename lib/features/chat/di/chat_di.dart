import '../../../core/di/service_locator.dart';
import '../../users/application/use_cases/get_profile_use_case.dart';
import '../application/use_cases/create_conversation_use_case.dart';
import '../application/use_cases/list_conversations_use_case.dart';
import '../application/use_cases/send_message_use_case.dart';
import '../application/use_cases/watch_messages_use_case.dart';
import '../domain/repositories/chat_repository.dart';
import '../infrastructure/in_memory_chat_repository.dart';

class ChatDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (locator.isRegistered<ChatRepository>()) return;
    locator.registerLazySingleton<ChatRepository>(InMemoryChatRepository.new);
    locator.registerFactory<CreateConversationUseCase>(
      () => CreateConversationUseCase(
        locator.get<ChatRepository>(),
        locator.get<GetProfileUseCase>(),
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
