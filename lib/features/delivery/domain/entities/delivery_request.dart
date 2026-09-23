import '../../../../core/errors/exceptions.dart';
import 'delivery_mode.dart';

/// Represents a delivery request associated with an order.
/// Enforces RN01: The order must be confirmed before requesting external drivers.
class DeliveryRequest {
  final String id;
  final String orderId;
  final String customerId;
  final String storeId;
  final DeliveryMode deliveryMode;
  final DeliveryExecutionStatus status;
  final double suggestedFee;
  final double initialCustomerOffer;
  final String? assignedDriverId;
  final DateTime createdAt;

  DeliveryRequest({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.storeId,
    required this.deliveryMode,
    required this.status,
    required this.suggestedFee,
    required this.initialCustomerOffer,
    required bool isOrderConfirmedByStore, // RN01
    this.assignedDriverId,
    required this.createdAt,
  }) {
    // RN01 Enforcement:
    if (!isOrderConfirmedByStore && deliveryMode == DeliveryMode.externalDriver) {
      throw const DomainException(
        'RN01: El establecimiento debe confirmar el pedido antes de buscar repartidor.',
      );
    }
  }

  DeliveryRequest copyWithAssignedDriver({
    required String driverId,
  }) {
    return DeliveryRequest(
      id: id,
      orderId: orderId,
      customerId: customerId,
      storeId: storeId,
      deliveryMode: deliveryMode,
      status: DeliveryExecutionStatus.driverAssigned,
      suggestedFee: suggestedFee,
      initialCustomerOffer: initialCustomerOffer,
      isOrderConfirmedByStore: true,
      assignedDriverId: driverId,
      createdAt: createdAt,
    );
  }
}
