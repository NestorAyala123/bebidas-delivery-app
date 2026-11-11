import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/order.dart';
import '../entities/order_delivery_method.dart';
import '../entities/order_status.dart';

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
  Future<Result<Order, Failure>> updateOrderStatus({
    required String orderId,
    required String storeId,
    required OrderStatus status,
  });
  Future<Result<Order, Failure>> cancelOrder({
    required String orderId,
    required String customerId,
  });
  Future<Result<Order, Failure>> changeDeliveryMethodAfterNoDrivers({
    required String orderId,
    required String customerId,
    required OrderDeliveryMethod deliveryMethod,
  });
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(String customerId);
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId);
}
