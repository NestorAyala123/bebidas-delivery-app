import '../../../../core/di/service_locator.dart';
import '../domain/repositories/order_repository.dart';
import '../infrastructure/repositories/in_memory_order_repository.dart';
import '../presentation/controllers/order_flow_controller.dart';
import '../presentation/order_flow_factory.dart';

/// Módulo de Inyección de Dependencias para Pedidos (David).
class OrdersDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<OrderRepository>()) {
      locator.registerLazySingleton<OrderRepository>(
        () => InMemoryOrderRepository(),
      );
    }

    if (!locator.isRegistered<OrderFlowController>()) {
      locator.registerFactory<OrderFlowController>(
        () => buildOrderFlowController(
          repository: locator.get<OrderRepository>(),
        ),
      );
    }
  }
}
