enum DeliveryOfferStatus {
  pending,
  accepted,
  rejected,
  closedByAnotherAcceptance,
  cancelledByDriver;

  bool get isActive => this == DeliveryOfferStatus.pending;
}

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
}
