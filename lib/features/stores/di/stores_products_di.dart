import '../../../../core/di/service_locator.dart';
import '../../products/application/use_cases/save_product_use_case.dart';
import '../../products/application/use_cases/update_product_availability_use_case.dart';
import '../../products/domain/repositories/product_repository.dart';
import '../../products/infrastructure/repositories/in_memory_product_repository.dart';
import '../application/use_cases/save_store_use_case.dart';
import '../application/use_cases/update_store_status_use_case.dart';
import '../domain/repositories/store_repository.dart';
import '../infrastructure/repositories/in_memory_store_repository.dart';

class StoresProductsDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<StoreRepository>()) {
      locator.registerLazySingleton<StoreRepository>(
        InMemoryStoreRepository.new,
      );
    }
    if (!locator.isRegistered<ProductRepository>()) {
      locator.registerLazySingleton<ProductRepository>(
        InMemoryProductRepository.new,
      );
    }
    if (!locator.isRegistered<SaveStoreUseCase>()) {
      locator.registerLazySingleton(
        () => SaveStoreUseCase(locator.get<StoreRepository>()),
      );
    }
    if (!locator.isRegistered<UpdateStoreStatusUseCase>()) {
      locator.registerLazySingleton(
        () => UpdateStoreStatusUseCase(locator.get<StoreRepository>()),
      );
    }
    if (!locator.isRegistered<SaveProductUseCase>()) {
      locator.registerLazySingleton(
        () => SaveProductUseCase(locator.get<ProductRepository>()),
      );
    }
    if (!locator.isRegistered<UpdateProductAvailabilityUseCase>()) {
      locator.registerLazySingleton(
        () =>
            UpdateProductAvailabilityUseCase(locator.get<ProductRepository>()),
      );
    }
  }
}
