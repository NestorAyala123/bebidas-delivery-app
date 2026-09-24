import '../../../../core/errors/exceptions.dart';
import 'delivery_mode.dart';
import 'delivery_status.dart';

/// Represents a delivery request associated with an order.
/// 100% pure Dart, independent of Flutter and Firebase.
/// Enforces RN01: The order must be confirmed before requesting external drivers.
class DeliveryRequest {
  final String id;
  final String orderId;
  final String customerId;
  final String storeId;
  final String originAddress;
  final String destinationAddress;
  final double? distanceInKm;
  final double referenceFare;
  final DeliveryMode deliveryMode;
  final DeliveryStatus status;
  final double? initialCustomerOffer;
  final String? assignedDriverId;
  final DateTime createdAt;

  DeliveryRequest({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.storeId,
    required this.originAddress,
    required this.destinationAddress,
    this.distanceInKm,
    required this.referenceFare,
    this.deliveryMode = DeliveryMode.externalDriver,
    this.status = DeliveryStatus.pendingOffer,
    this.initialCustomerOffer,
    required bool isOrderConfirmedByStore, // RN01
    this.assignedDriverId,
    required this.createdAt,
  }) {
    assert(id.trim().isNotEmpty, 'El id no puede estar vacío');
    assert(orderId.trim().isNotEmpty, 'El orderId no puede estar vacío');
    assert(originAddress.trim().isNotEmpty, 'El origen no puede estar vacío');
    assert(
      destinationAddress.trim().isNotEmpty,
      'El destino no puede estar vacío',
    );
    assert(referenceFare >= 0, 'La tarifa referencial no puede ser negativa');
    if (distanceInKm != null) {
      assert(distanceInKm! >= 0, 'La distancia no puede ser negativa');
    }

    // RN01 Enforcement:
    if (!isOrderConfirmedByStore &&
        deliveryMode == DeliveryMode.externalDriver) {
      throw const DomainException(
        'RN01: El establecimiento debe confirmar el pedido antes de buscar repartidor.',
      );
    }
  }

  /// Backwards compatibility getter for suggested fee
  double get suggestedFee => referenceFare;

  /// Returns a copy of the request with an assigned driver
  DeliveryRequest copyWithAssignedDriver({required String driverId}) {
    return DeliveryRequest(
      id: id,
      orderId: orderId,
      customerId: customerId,
      storeId: storeId,
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      distanceInKm: distanceInKm,
      referenceFare: referenceFare,
      deliveryMode: deliveryMode,
      status: DeliveryStatus.driverAssigned,
      initialCustomerOffer: initialCustomerOffer,
      isOrderConfirmedByStore: true,
      assignedDriverId: driverId,
      createdAt: createdAt,
    );
  }

  /// Returns a copy of the request with an updated status
  DeliveryRequest copyWithStatus(DeliveryStatus newStatus) {
    return DeliveryRequest(
      id: id,
      orderId: orderId,
      customerId: customerId,
      storeId: storeId,
      originAddress: originAddress,
      destinationAddress: destinationAddress,
      distanceInKm: distanceInKm,
      referenceFare: referenceFare,
      deliveryMode: deliveryMode,
      status: newStatus,
      initialCustomerOffer: initialCustomerOffer,
      isOrderConfirmedByStore: true,
      assignedDriverId: assignedDriverId,
      createdAt: createdAt,
    );
  }
}
