import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';

/// Read-only snapshot of an order needed by the delivery module.
class OrderDeliveryInfo {
  final String orderId;
  final String storeId;
  final String customerId;
  final String pickupAddress;
  final String deliveryAddress;
  final bool isConfirmedByStore; // RN01
  final int totalItemsCount;
  final double orderTotal;

  const OrderDeliveryInfo({
    required this.orderId,
    required this.storeId,
    required this.customerId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.isConfirmedByStore,
    required this.totalItemsCount,
    required this.orderTotal,
  });
}

/// Public contract exposed by the Orders module.
/// Other modules (like Delivery) must consume this contract, NEVER the internal infrastructure.
abstract class OrderDeliveryContract {
  Future<Result<OrderDeliveryInfo, Failure>> getOrderDeliveryInfo(
    String orderId,
  );
}
