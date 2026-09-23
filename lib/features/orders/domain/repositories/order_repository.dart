import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/order.dart';
import '../entities/order_status.dart';

abstract class OrderRepository {
  Future<Result<Order, Failure>> getOrderById(String orderId);
  Future<Result<Order, Failure>> createOrder(Order order);
  Future<Result<void, Failure>> updateOrderStatus(String orderId, OrderStatus status);
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(String customerId);
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId);
}
