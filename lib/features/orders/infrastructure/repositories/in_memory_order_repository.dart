import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/repositories/order_repository.dart';

class InMemoryOrderRepository implements OrderRepository {
  final Map<String, Order> _orders = {};

  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) async {
    final order = _orders[orderId];

    if (order == null) {
      return const FailureResult<Order, Failure>(
        NotFoundFailure('Pedido no encontrado'),
      );
    }

    return Success<Order, Failure>(order);
  }

  @override
  Future<Result<Order, Failure>> createOrder(Order order) async {
    if (_orders.containsKey(order.id)) {
      return const FailureResult<Order, Failure>(
        ValidationFailure('Ya existe un pedido con ese identificador'),
      );
    }

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
      final updatedOrder = order.copyWithStatus(status);
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
      final updatedOrder = order.copyWithStatus(OrderStatus.cancelled);
      _orders[orderId] = updatedOrder;
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
    final orders = _orders.values
        .where((order) => order.customerId == customerId)
        .toList();

    return Success<List<Order>, Failure>(orders);
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId) async {
    final orders = _orders.values
        .where((order) => order.storeId == storeId)
        .toList();

    return Success<List<Order>, Failure>(orders);
  }
}
