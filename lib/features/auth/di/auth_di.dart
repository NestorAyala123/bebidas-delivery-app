import '../../../../core/di/service_locator.dart';
import '../application/use_cases/login_use_case.dart';
import '../domain/repositories/auth_repository.dart';
import '../infrastructure/mock_auth_repository.dart';

class AuthDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<AuthRepository>()) {
      locator.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    }

    if (!locator.isRegistered<LoginUseCase>()) {
      locator.registerFactory<LoginUseCase>(
        () => LoginUseCase(locator.get<AuthRepository>()),
      );
    }
  }
}
