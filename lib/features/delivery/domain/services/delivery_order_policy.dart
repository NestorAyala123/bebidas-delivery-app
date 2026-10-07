import '../../../orders/domain/contracts/order_delivery_contract.dart';

/// Domain policy that evaluates whether an order is eligible for external delivery dispatch.
/// Completely decoupled from Firebase, Flutter, and internal Orders infrastructure.
class DeliveryOrderPolicy {
  const DeliveryOrderPolicy();

  /// Evaluates the activation rules for creating a DeliveryRequest:
  /// - Pedido no confirmado -> false (NO inicia búsqueda externa)
  /// - Pedido confirmado + retiro en local -> false (NO inicia delivery externo)
  /// - Pedido confirmado + delivery propio del comercio -> false (NO inicia delivery externo)
  /// - Pedido confirmado + delivery externo -> true (PUEDE iniciar creación)
  bool canCreateDeliveryRequest(OrderDeliveryInfo orderInfo) {
    if (!orderInfo.canInitiateExternalDelivery) {
      return false;
    }

    if (orderInfo.orderId.trim().isEmpty ||
        orderInfo.pickupAddress.trim().isEmpty ||
        orderInfo.deliveryAddress.trim().isEmpty) {
      return false;
    }

    return true;
  }
}
