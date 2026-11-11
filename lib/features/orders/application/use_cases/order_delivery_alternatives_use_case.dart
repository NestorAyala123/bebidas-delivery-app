import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../stores/domain/entities/store.dart';
import '../../../stores/domain/repositories/store_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_delivery_method.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';

class OrderDeliveryAlternativesUseCase {
  final OrderRepository orders;
  final StoreRepository stores;

  const OrderDeliveryAlternativesUseCase({
    required this.orders,
    required this.stores,
  });

  Future<Result<List<OrderDeliveryMethod>, Failure>> availableFor({
    required Order order,
    required String customerId,
  }) async {
    final orderResult = await orders.getOrderById(order.id);
    late final Order currentOrder;
    switch (orderResult) {
      case Success(:final data):
        currentOrder = data;
      case FailureResult(:final failure):
        return FailureResult(failure);
    }

    if (currentOrder.customerId != customerId.trim()) {
      return const FailureResult(
        UnauthorizedFailure('No autorizado para consultar este pedido.'),
      );
    }
    if (currentOrder.status != OrderStatus.noDriversAvailable) {
      return const FailureResult(
        BusinessRuleFailure(
          'Las alternativas solo están disponibles cuando no hay repartidores.',
        ),
      );
    }

    final storeResult = await stores.getStoreById(currentOrder.storeId);
    late final Store store;
    switch (storeResult) {
      case Success(:final data):
        store = data;
      case FailureResult(:final failure):
        return FailureResult(failure);
    }
    if (!store.isOpen) {
      return const Success([]);
    }

    return Success([
      if (store.allowsPickup) OrderDeliveryMethod.pickup,
      if (store.hasOwnDelivery) OrderDeliveryMethod.storeDelivery,
    ]);
  }

  Future<Result<Order, Failure>> select({
    required Order order,
    required String customerId,
    required OrderDeliveryMethod deliveryMethod,
  }) async {
    final options = await availableFor(order: order, customerId: customerId);
    late final List<OrderDeliveryMethod> availableMethods;
    switch (options) {
      case Success(:final data):
        availableMethods = data;
      case FailureResult(:final failure):
        return FailureResult(failure);
    }
    if (!availableMethods.contains(deliveryMethod)) {
      return const FailureResult(
        BusinessRuleFailure(
          'El comercio no ofrece esta alternativa de entrega.',
        ),
      );
    }

    return orders.changeDeliveryMethodAfterNoDrivers(
      orderId: order.id,
      customerId: customerId.trim(),
      deliveryMethod: deliveryMethod,
    );
  }

  Future<Result<Order, Failure>> waitForAvailableDrivers({
    required Order order,
    required String customerId,
  }) async {
    final orderResult = await orders.getOrderById(order.id);
    late final Order currentOrder;
    switch (orderResult) {
      case Success(:final data):
        currentOrder = data;
      case FailureResult(:final failure):
        return FailureResult(failure);
    }

    if (currentOrder.customerId != customerId.trim()) {
      return const FailureResult(
        UnauthorizedFailure('No autorizado para modificar este pedido.'),
      );
    }
    if (currentOrder.status != OrderStatus.noDriversAvailable) {
      return const FailureResult(
        BusinessRuleFailure(
          'El pedido ya no está esperando una alternativa de entrega.',
        ),
      );
    }

    return orders.updateOrderStatus(
      orderId: currentOrder.id,
      storeId: currentOrder.storeId,
      status: OrderStatus.lookingForDriver,
    );
  }
}
