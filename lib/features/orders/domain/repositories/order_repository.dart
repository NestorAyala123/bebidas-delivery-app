import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<Result<Order, Failure>> getOrderById(String orderId);
  Future<Result<Order, Failure>> createOrder(Order order);
  Future<Result<Order, Failure>> confirmOrder({
    required String orderId,
    required String storeId,
  });
  Future<Result<Order, Failure>> rejectOrder({
    required String orderId,
    required String storeId,
    required String reason,
  });
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(String customerId);
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId);
}
