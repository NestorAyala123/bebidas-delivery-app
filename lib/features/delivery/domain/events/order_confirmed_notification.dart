/// Conceptual domain event representing that an order has been confirmed by a store
/// and is ready to be processed by the delivery module.
/// Pure Dart DTO without premature infrastructure (no EventBus, no Firebase Messaging).
class OrderConfirmedNotification {
  final String orderId;
  final String storeId;
  final String customerId;
  final String pickupAddress;
  final String deliveryAddress;
  final bool requiresExternalDelivery;
  final double? distanceInKm;
  final double orderTotal;
  final DateTime confirmedAt;

  const OrderConfirmedNotification({
    required this.orderId,
    required this.storeId,
    required this.customerId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.requiresExternalDelivery,
    this.distanceInKm,
    required this.orderTotal,
    required this.confirmedAt,
  });

  /// Evaluates whether this notification should trigger an external driver search
  bool get shouldDispatchExternalDriver => requiresExternalDelivery;
}
