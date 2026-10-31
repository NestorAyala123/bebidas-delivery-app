import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../domain/entities/order.dart';
import '../domain/entities/order_status.dart';
import '../domain/repositories/order_repository.dart';

/// In-memory implementation of [OrderRepository] for prototypes and state persistence.
class InMemoryOrderRepository implements OrderRepository {
  final Map<String, Order> _orders = {};

  InMemoryOrderRepository([List<Order>? initialOrders]) {
    if (initialOrders != null) {
      for (final order in initialOrders) {
        _orders[order.id] = order;
      }
    }
  }

  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) async {
    final order = _orders[orderId.trim()];
    if (order == null) {
      return const FailureResult(NotFoundFailure('Pedido no encontrado.'));
    }
    return Success(order);
  }

  @override
  Future<Result<Order, Failure>> createOrder(Order order) async {
    _orders[order.id] = order;
    return Success(order);
  }

  @override
  Future<Result<Order, Failure>> confirmOrder({
    required String orderId,
    required String storeId,
  }) async {
    final order = _orders[orderId.trim()];
    if (order == null) {
      return const FailureResult(NotFoundFailure('Pedido no encontrado.'));
    }
    if (order.storeId != storeId.trim()) {
      return const FailureResult(
        UnauthorizedFailure('No autorizado para gestionar este pedido.'),
      );
    }
    try {
      final confirmed = order.copyWithStatus(
        OrderStatus.confirmed,
        confirmedAt: DateTime.now(),
      );
      _orders[confirmed.id] = confirmed;
      return Success(confirmed);
    } catch (e) {
      return FailureResult(ValidationFailure(e.toString()));
    }
  }

  @override
  Future<Result<Order, Failure>> rejectOrder({
    required String orderId,
    required String storeId,
    required String reason,
  }) async {
    final order = _orders[orderId.trim()];
    if (order == null) {
      return const FailureResult(NotFoundFailure('Pedido no encontrado.'));
    }
    if (order.storeId != storeId.trim()) {
      return const FailureResult(
        UnauthorizedFailure('No autorizado para gestionar este pedido.'),
      );
    }
    try {
      final rejected = order.copyWithStatus(
        OrderStatus.rejected,
        rejectionReason: reason,
      );
      _orders[rejected.id] = rejected;
      return Success(rejected);
    } catch (e) {
      return FailureResult(ValidationFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(
    String customerId,
  ) async {
    final cleanId = customerId.trim();
    final customerOrders = _orders.values
        .where((o) => o.customerId == cleanId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(customerOrders);
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId) async {
    final cleanId = storeId.trim();
    final storeOrders = _orders.values
        .where((o) => o.storeId == cleanId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(storeOrders);
  }
}
