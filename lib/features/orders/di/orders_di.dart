import '../../../../core/di/service_locator.dart';
import '../application/use_cases/confirm_order_use_case.dart';
import '../application/use_cases/cancel_order_use_case.dart';
import '../application/use_cases/create_order_use_case.dart';
import '../application/use_cases/get_customer_orders_use_case.dart';
import '../application/use_cases/get_store_orders_use_case.dart';
import '../application/use_cases/order_delivery_alternatives_use_case.dart';
import '../application/use_cases/reject_order_use_case.dart';
import '../application/use_cases/update_order_status_use_case.dart';
import '../domain/repositories/order_repository.dart';
import '../infrastructure/in_memory_order_repository.dart';
import '../../stores/domain/repositories/store_repository.dart';

/// Dependency injection module for the Orders feature.
class OrdersDi implements FeatureDiModule {
  @override
  void registerDependencies(ServiceLocator locator) {
    if (!locator.isRegistered<OrderRepository>()) {
      locator.registerLazySingleton<OrderRepository>(
        () => InMemoryOrderRepository(),
      );
    }

    if (!locator.isRegistered<CreateOrderUseCase>()) {
      locator.registerFactory<CreateOrderUseCase>(
        () => CreateOrderUseCase(
          repository: locator.get<OrderRepository>(),
          generateOrderId: () =>
              'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        ),
      );
    }

    if (!locator.isRegistered<GetCustomerOrdersUseCase>()) {
      locator.registerFactory<GetCustomerOrdersUseCase>(
        () => GetCustomerOrdersUseCase(locator.get<OrderRepository>()),
      );
    }

    if (!locator.isRegistered<ConfirmOrderUseCase>()) {
      locator.registerFactory<ConfirmOrderUseCase>(
        () => ConfirmOrderUseCase(locator.get<OrderRepository>()),
      );
    }

    if (!locator.isRegistered<RejectOrderUseCase>()) {
      locator.registerFactory<RejectOrderUseCase>(
        () => RejectOrderUseCase(locator.get<OrderRepository>()),
      );
    }

    if (!locator.isRegistered<GetStoreOrdersUseCase>()) {
      locator.registerFactory<GetStoreOrdersUseCase>(
        () => GetStoreOrdersUseCase(locator.get<OrderRepository>()),
      );
    }

    if (!locator.isRegistered<UpdateOrderStatusUseCase>()) {
      locator.registerFactory<UpdateOrderStatusUseCase>(
        () => UpdateOrderStatusUseCase(locator.get<OrderRepository>()),
      );
    }

    if (!locator.isRegistered<CancelOrderUseCase>()) {
      locator.registerFactory<CancelOrderUseCase>(
        () => CancelOrderUseCase(locator.get<OrderRepository>()),
      );
    }

    if (!locator.isRegistered<OrderDeliveryAlternativesUseCase>()) {
      locator.registerFactory<OrderDeliveryAlternativesUseCase>(
        () => OrderDeliveryAlternativesUseCase(
          orders: locator.get<OrderRepository>(),
          stores: locator.get<StoreRepository>(),
        ),
      );
    }
  }
}
