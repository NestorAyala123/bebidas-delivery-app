import '../../../../core/di/service_locator.dart';
import '../application/use_cases/login_use_case.dart';

class AuthDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    // Registered lazy singletons or factories for Auth
    // Repositories will be registered when Firebase implementations are ready.
    if (locator.isRegistered<LoginUseCase>()) return;
    // Example factory registration:
    // locator.registerFactory<LoginUseCase>(() => LoginUseCase(locator.get<AuthRepository>()));
  }
}
