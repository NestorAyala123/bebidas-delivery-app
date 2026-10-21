import '../../../core/di/service_locator.dart';
import '../../auth/infrastructure/mock_auth_repository.dart';
import '../application/use_cases/get_profile_use_case.dart';
import '../application/use_cases/list_contacts_use_case.dart';
import '../application/use_cases/update_profile_use_case.dart';
import '../domain/repositories/user_repository.dart';
import '../infrastructure/in_memory_user_repository.dart';

class UsersDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (locator.isRegistered<InMemoryUserRepository>()) return;
    locator.registerLazySingleton<InMemoryUserRepository>(
      () => InMemoryUserRepository(MockAccounts.all.map((a) => a.user)),
    );
    locator.registerLazySingleton<UserRepository>(
      () => locator.get<InMemoryUserRepository>(),
    );
    locator.registerFactory<GetProfileUseCase>(
      () => GetProfileUseCase(locator.get<UserRepository>()),
    );
    locator.registerFactory<UpdateProfileUseCase>(
      () => UpdateProfileUseCase(locator.get<UserRepository>()),
    );
    locator.registerFactory<ListContactsUseCase>(
      () => ListContactsUseCase(locator.get<UserRepository>()),
    );
  }
}
