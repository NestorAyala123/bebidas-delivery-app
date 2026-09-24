import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';

/// Delivery methods supported by an order (Business Rule RN02).
enum OrderDeliveryMethod {
  /// Retiro en el local por el cliente
  pickup,

  /// Delivery propio gestionado por el establecimiento comercial
  storeDelivery,

  /// Repartidor externo mediante negociación en la app
  externalDelivery;

  /// True if this order relies on an external driver
  bool get isExternal => this == OrderDeliveryMethod.externalDelivery;
}

/// Read-only snapshot of an order needed by the delivery module.
/// Public integration DTO exposed across modules without coupling to internal order infrastructure.
class OrderDeliveryInfo {
  final String orderId;
  final String storeId;
  final String customerId;
  final String pickupAddress;
  final String deliveryAddress;
  final bool isConfirmedByStore; // RN01
  final OrderDeliveryMethod deliveryMethod; // RN02: Explicit delivery method (required, no silent defaults)

  /// Distance between pickup and destination.
  /// NOTE: This field is strictly OPTIONAL for the Orders module.
  /// Orders is only responsible for providing pickupAddress and deliveryAddress.
  /// Delivery (together with location) holds the ultimate responsibility of calculating distance and fare.
  final double? distanceInKm;

  final int totalItemsCount;
  final double orderTotal;

  const OrderDeliveryInfo({
    required this.orderId,
    required this.storeId,
    required this.customerId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.isConfirmedByStore,
    required this.deliveryMethod,
    this.distanceInKm,
    required this.totalItemsCount,
    required this.orderTotal,
  });

  /// Derived property: true only when order explicitly specifies external delivery.
  bool get requiresExternalDelivery =>
      deliveryMethod == OrderDeliveryMethod.externalDelivery;

  /// Evaluates if this order meets all business criteria to initiate an external delivery request:
  /// - Pedido no confirmado -> false (NO inicia búsqueda externa)
  /// - Pedido confirmado + retiro en tienda -> false (NO inicia delivery externo)
  /// - Pedido confirmado + delivery propio -> false (NO inicia delivery externo)
  /// - Pedido confirmado + delivery externo -> true (PUEDE iniciar creación de DeliveryRequest)
  bool get canInitiateExternalDelivery =>
      isConfirmedByStore && requiresExternalDelivery;
}

/// Public contract exposed by the Orders module.
/// Other modules (like Delivery) must consume this contract, NEVER internal infrastructure.
abstract class OrderDeliveryContract {
  Future<Result<OrderDeliveryInfo, Failure>> getOrderDeliveryInfo(
    String orderId,
  );
}
