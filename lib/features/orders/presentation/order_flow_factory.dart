import '../../../../core/di/service_locator.dart';
import '../domain/repositories/order_repository.dart';
import '../infrastructure/repositories/in_memory_order_repository.dart';
import 'controllers/order_flow_controller.dart';

/// Construye el controlador de pedidos con el repositorio registrado o uno
/// en memoria para demostraciones.
OrderFlowController buildOrderFlowController({
  OrderRepository? repository,
  bool storeHasOwnDelivery = true,
  bool storeAllowsExternalDelivery = true,
  bool storeAllowsPickup = true,
}) {
  final orderRepository =
      repository ??
      (sl.isRegistered<OrderRepository>()
          ? sl.get<OrderRepository>()
          : InMemoryOrderRepository());

  return OrderFlowController(
    orderRepository: orderRepository,
    storeHasOwnDelivery: storeHasOwnDelivery,
    storeAllowsExternalDelivery: storeAllowsExternalDelivery,
    storeAllowsPickup: storeAllowsPickup,
  );
}
