enum DeliveryOfferStatus {
  pending,
  accepted,
  rejected,
  closedByAnotherAcceptance,
  cancelledByDriver;

  bool get isActive => this == DeliveryOfferStatus.pending;

  String get label => switch (this) {
    DeliveryOfferStatus.pending => 'Pendiente',
    DeliveryOfferStatus.accepted => 'Aceptada',
    DeliveryOfferStatus.rejected => 'Rechazada',
    DeliveryOfferStatus.closedByAnotherAcceptance => 'Cerrada',
    DeliveryOfferStatus.cancelledByDriver => 'Cancelada',
  };
}

/// Oferta económica enviada por un repartidor para una solicitud de entrega.
class DeliveryOffer {
  final String id;
  final String deliveryRequestId;
  final String driverId;
  final String driverName;
  final double offeredAmount;
  final bool isCounterOffer;
  final DeliveryOfferStatus status;
  final DateTime createdAt;

  const DeliveryOffer({
    required this.id,
    required this.deliveryRequestId,
    required this.driverId,
    required this.driverName,
    required this.offeredAmount,
    this.isCounterOffer = false,
    this.status = DeliveryOfferStatus.pending,
    required this.createdAt,
  }) : assert(offeredAmount > 0, 'La oferta debe ser mayor a 0');

  bool get isAccepted => status == DeliveryOfferStatus.accepted;

  bool get wasClosedByAnotherAcceptance =>
      status == DeliveryOfferStatus.closedByAnotherAcceptance;

  String get amountLabel => '\$${offeredAmount.toStringAsFixed(2)}';

  DeliveryOffer copyWithStatus(DeliveryOfferStatus newStatus) {
    return DeliveryOffer(
      id: id,
      deliveryRequestId: deliveryRequestId,
      driverId: driverId,
      driverName: driverName,
      offeredAmount: offeredAmount,
      isCounterOffer: isCounterOffer,
      status: newStatus,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryOffer &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'DeliveryOffer(id: $id, driver: $driverName, amount: $offeredAmount, '
      'status: ${status.name})';
}
