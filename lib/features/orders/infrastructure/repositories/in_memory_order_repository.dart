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
    return order == null
        ? const FailureResult<Order, Failure>(
            NotFoundFailure('Pedido no encontrado'),
          )
        : Success(order);
  }

  @override
  Future<Result<Order, Failure>> createOrder(Order order) async {
    if (_orders.containsKey(order.id)) {
      return const FailureResult<Order, Failure>(
        ValidationFailure('Ya existe un pedido con ese identificador'),
      );
    }
    _orders[order.id] = order;
    return Success(order);
  }

  @override
  Future<Result<void, Failure>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final order = _orders[orderId];
    if (order == null) {
      return const FailureResult<void, Failure>(
        NotFoundFailure('Pedido no encontrado'),
      );
    }
    _orders[orderId] = order.copyWithStatus(status);
    return const Success<void, Failure>(null);
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(
    String customerId,
  ) async {
    return Success(
      _orders.values.where((order) => order.customerId == customerId).toList(),
    );
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId) async {
    return Success(
      _orders.values.where((order) => order.storeId == storeId).toList(),
    );
  }
}
