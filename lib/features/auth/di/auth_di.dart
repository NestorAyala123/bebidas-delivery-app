import '../../../core/di/service_locator.dart';
import '../../users/infrastructure/in_memory_user_repository.dart';
import '../infrastructure/mock_auth_repository.dart';
import '../application/use_cases/check_access_rules_use_case.dart';
import '../application/use_cases/get_current_user_use_case.dart';
import '../application/use_cases/login_use_case.dart';
import '../application/use_cases/logout_use_case.dart';
import '../application/use_cases/register_use_case.dart';
import '../presentation/state/auth_controller.dart';
import '../domain/repositories/auth_repository.dart';

class AuthDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (locator.isRegistered<AuthController>()) return;
    locator.registerLazySingleton<AuthRepository>(
      () => MockAuthRepository(users: locator.get<InMemoryUserRepository>()),
    );
    locator.registerFactory<LoginUseCase>(
      () => LoginUseCase(locator.get<AuthRepository>()),
    );
    locator.registerFactory<RegisterUseCase>(
      () => RegisterUseCase(locator.get<AuthRepository>()),
    );
    locator.registerFactory<LogoutUseCase>(
      () => LogoutUseCase(locator.get<AuthRepository>()),
    );
    locator.registerFactory<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(locator.get<AuthRepository>()),
    );
    locator.registerSingleton<CheckAccessRulesUseCase>(
      const CheckAccessRulesUseCase(),
    );
    locator.registerLazySingleton<AuthController>(
      () => AuthController(
        loginUseCase: locator.get<LoginUseCase>(),
        registerUseCase: locator.get<RegisterUseCase>(),
        logoutUseCase: locator.get<LogoutUseCase>(),
        getCurrentUserUseCase: locator.get<GetCurrentUserUseCase>(),
      ),
    );
  }
}
