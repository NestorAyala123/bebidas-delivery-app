import '../../../../core/di/service_locator.dart';
import '../application/use_cases/add_to_cart_use_case.dart';
import '../application/use_cases/calculate_cart_totals_use_case.dart';
import '../application/use_cases/clear_cart_use_case.dart';
import '../application/use_cases/remove_from_cart_use_case.dart';
import '../application/use_cases/update_cart_quantity_use_case.dart';
import '../domain/repositories/cart_repository.dart';
import '../infrastructure/in_memory_cart_repository.dart';

/// Dependency injection module for the Cart feature.
class CartDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<CartRepository>()) {
      locator.registerLazySingleton<CartRepository>(
        () => InMemoryCartRepository(),
      );
    }

    if (!locator.isRegistered<AddToCartUseCase>()) {
      locator.registerFactory<AddToCartUseCase>(
        () => AddToCartUseCase(locator.get<CartRepository>()),
      );
    }

    if (!locator.isRegistered<UpdateCartQuantityUseCase>()) {
      locator.registerFactory<UpdateCartQuantityUseCase>(
        () => UpdateCartQuantityUseCase(locator.get<CartRepository>()),
      );
    }

    if (!locator.isRegistered<RemoveFromCartUseCase>()) {
      locator.registerFactory<RemoveFromCartUseCase>(
        () => RemoveFromCartUseCase(locator.get<CartRepository>()),
      );
    }

    if (!locator.isRegistered<ClearCartUseCase>()) {
      locator.registerFactory<ClearCartUseCase>(
        () => ClearCartUseCase(locator.get<CartRepository>()),
      );
    }

    if (!locator.isRegistered<CalculateCartTotalsUseCase>()) {
      locator.registerFactory<CalculateCartTotalsUseCase>(
        () => const CalculateCartTotalsUseCase(),
      );
    }
  }
}

