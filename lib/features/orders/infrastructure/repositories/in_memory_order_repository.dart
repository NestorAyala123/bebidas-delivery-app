import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../delivery/domain/entities/delivery_mode.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_delivery_method.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/order_repository.dart';

/// Repositorio en memoria de pedidos con soporte completo para las reglas de
/// negocio, transiciones, operaciones de comercio, y datos de demostración.
class InMemoryOrderRepository implements OrderRepository {
  final Map<String, Order> _orders = {};

  InMemoryOrderRepository({List<Order>? initialOrders}) {
    final list = initialOrders ?? _seedOrders();
    for (final order in list) {
      _orders[order.id] = order;
    }
  }

  static List<Order> _seedOrders() {
    final base = DateTime(2026, 11, 15, 9);
    const items = [
      OrderItem(
        productId: 'prod-1',
        productName: 'Cerveza Pilsen 330 ml',
        frozenUnitPrice: 2.50,
        quantity: 6,
      ),
      OrderItem(
        productId: 'prod-2',
        productName: 'Vino tinto Reserva',
        frozenUnitPrice: 18.00,
        quantity: 1,
      ),
    ];

    return [
      Order(
        id: 'ord-demo-01',
        customerId: 'customer-demo',
        storeId: 'store-001',
        items: items,
        status: OrderStatus.confirmed,
        deliveryAddress: 'Av. Malecón Jaime Chávez, Manta',
        deliveryMode: DeliveryMode.externalDriver,
        deliveryFee: 3.50,
        createdAt: base,
        confirmedAt: base.add(const Duration(minutes: 3)),
      ),
      Order(
        id: 'ord-demo-02',
        customerId: 'customer-demo',
        storeId: 'store-001',
        items: items,
        status: OrderStatus.delivered,
        deliveryAddress: 'Barrio Santa Martha, Manta',
        deliveryMode: DeliveryMode.pickupAtStore,
        paymentMethod: PaymentMethod.cash,
        deliveryFee: 0,
        createdAt: base.subtract(const Duration(days: 3)),
        confirmedAt: base.subtract(const Duration(days: 3)),
      ),
      Order(
        id: 'ord-demo-03',
        customerId: 'customer-demo',
        storeId: 'store-002',
        items: items,
        status: OrderStatus.lookingForDriver,
        deliveryAddress: 'Av. Flavio Reyes, Manta',
        deliveryMode: DeliveryMode.externalDriver,
        paymentMethod: PaymentMethod.transfer,
        deliveryFee: 2.00,
        createdAt: base.add(const Duration(hours: 1)),
        confirmedAt: base.add(const Duration(hours: 1)),
      ),
      Order(
        id: 'ord-demo-04',
        customerId: 'customer-demo',
        storeId: 'store-001',
        items: items,
        status: OrderStatus.created,
        deliveryAddress: 'Calle 13 y Av. 24, Manta',
        deliveryMode: DeliveryMode.externalDriver,
        createdAt: base.add(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) async {
    final order = _orders[orderId];
    if (order == null) {
      return FailureResult<Order, Failure>(
        NotFoundFailure('No se encontró el pedido $orderId'),
      );
    }
    return Success<Order, Failure>(order);
  }

  @override
  Future<Result<Order, Failure>> createOrder(Order order) async {
    _orders[order.id] = order;
    return Success<Order, Failure>(order);
  }

  @override
  Future<Result<Order, Failure>> confirmOrder({
    required String orderId,
    required String storeId,
  }) async {
    final order = _orders[orderId];

    if (order == null) {
      return const FailureResult<Order, Failure>(
        NotFoundFailure('Pedido no encontrado'),
      );
    }

    if (order.storeId != storeId) {
      return const FailureResult<Order, Failure>(
        UnauthorizedFailure('El pedido no pertenece a este comercio'),
      );
    }

    try {
      final now = DateTime.now();
      final updatedOrder = order.copyWithStatus(
        OrderStatus.confirmed,
        confirmedAt: now,
        changedAt: now,
      );

      _orders[orderId] = updatedOrder;
      return Success<Order, Failure>(updatedOrder);
    } on DomainException catch (exception) {
      return FailureResult<Order, Failure>(
        BusinessRuleFailure(exception.toString()),
      );
    }
  }

  @override
  Future<Result<Order, Failure>> rejectOrder({
    required String orderId,
    required String storeId,
    required String reason,
  }) async {
    final order = _orders[orderId];

    if (order == null) {
      return const FailureResult<Order, Failure>(
        NotFoundFailure('Pedido no encontrado'),
      );
    }

    if (order.storeId != storeId) {
      return const FailureResult<Order, Failure>(
        UnauthorizedFailure('El pedido no pertenece a este comercio'),
      );
    }

    if (reason.trim().isEmpty) {
      return const FailureResult<Order, Failure>(
        ValidationFailure('Debe indicar el motivo del rechazo'),
      );
    }

    try {
      final updatedOrder = order.copyWithStatus(
        OrderStatus.rejected,
        rejectionReason: reason,
        changedAt: DateTime.now(),
      );

      _orders[orderId] = updatedOrder;
      return Success<Order, Failure>(updatedOrder);
    } on DomainException catch (exception) {
      return FailureResult<Order, Failure>(
        BusinessRuleFailure(exception.message),
      );
    }
  }

  @override
  Future<Result<Order, Failure>> updateOrderStatus({
    required String orderId,
    required String storeId,
    required OrderStatus status,
  }) async {
    final order = _orders[orderId];

    if (order == null) {
      return const FailureResult<Order, Failure>(
        NotFoundFailure('Pedido no encontrado'),
      );
    }

    if (order.storeId != storeId) {
      return const FailureResult<Order, Failure>(
        UnauthorizedFailure('El pedido no pertenece a este comercio'),
      );
    }

    try {
      final updatedOrder = order.copyWithStatus(
        status,
        changedAt: DateTime.now(),
      );
      _orders[orderId] = updatedOrder;
      return Success<Order, Failure>(updatedOrder);
    } on DomainException catch (exception) {
      return FailureResult<Order, Failure>(
        BusinessRuleFailure(exception.message),
      );
    }
  }

  @override
  Future<Result<Order, Failure>> cancelOrder({
    required String orderId,
    required String customerId,
  }) async {
    final order = _orders[orderId];

    if (order == null) {
      return const FailureResult<Order, Failure>(
        NotFoundFailure('Pedido no encontrado'),
      );
    }

    if (order.customerId != customerId) {
      return const FailureResult<Order, Failure>(
        UnauthorizedFailure('El pedido no pertenece a este cliente'),
      );
    }

    try {
      final updatedOrder = order.copyWithStatus(
        OrderStatus.cancelled,
        changedAt: DateTime.now(),
      );
      _orders[orderId] = updatedOrder;
      return Success<Order, Failure>(updatedOrder);
    } on DomainException catch (exception) {
      return FailureResult<Order, Failure>(
        BusinessRuleFailure(exception.message),
      );
    }
  }

  @override
  Future<Result<Order, Failure>> changeDeliveryMethodAfterNoDrivers({
    required String orderId,
    required String customerId,
    required OrderDeliveryMethod deliveryMethod,
  }) async {
    final order = _orders[orderId];

    if (order == null) {
      return const FailureResult<Order, Failure>(
        NotFoundFailure('Pedido no encontrado'),
      );
    }

    if (order.customerId != customerId) {
      return const FailureResult<Order, Failure>(
        UnauthorizedFailure('El pedido no pertenece a este cliente'),
      );
    }

    try {
      final updatedOrder = order.useAlternativeDeliveryMethod(
        deliveryMethod,
        changedAt: DateTime.now(),
      );
      _orders[updatedOrder.id] = updatedOrder;
      return Success<Order, Failure>(updatedOrder);
    } on DomainException catch (exception) {
      return FailureResult<Order, Failure>(
        BusinessRuleFailure(exception.message),
      );
    }
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(
    String customerId,
  ) async {
    final found =
        _orders.values.where((order) => order.customerId == customerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Success<List<Order>, Failure>(found);
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId) async {
    final found =
        _orders.values.where((order) => order.storeId == storeId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Success<List<Order>, Failure>(found);
  }
}
